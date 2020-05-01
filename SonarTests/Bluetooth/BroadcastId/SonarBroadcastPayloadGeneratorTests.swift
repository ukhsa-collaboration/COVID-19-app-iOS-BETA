//
//  ConcreteBroadcastIdGeneratorTests.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class SonarBroadcastPayloadGeneratorTests: XCTestCase {

    let dateFormatter = DateFormatter()
    let sonarEpoch = "2020-04-01T00:00:00Z"
    let registration = Registration(id: UUID(uuidString: "054DDC35-0287-4247-97BE-D9A3AF012E36")!, secretKey: Data(), broadcastRotationKey: SecKey.sampleEllipticCurveKey)
    let utcCalendar: Calendar = {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()
    
    var knownDate: Date!
    var slightlyLaterDate: Date!
    var muchLaterDate: Date!
    
    private var generator: SonarBroadcastPayloadGenerator!
    private var encrypter: MockEncrypter!
    private var storage: MockBroadcastRotationKeyStorage!

    override func setUp() {
        storage = MockBroadcastRotationKeyStorage(stubbedKey: nil)
        encrypter = MockEncrypter()
    }

    func test_returns_nil_when_provider_returns_nil() {
        struct NilEncrypterProvider: BroadcastIdEncrypterProvider {
            func getEncrypter() -> BroadcastIdEncrypter? { return nil }
        }
        generator = SonarBroadcastPayloadGenerator(storage: storage, persistence: PersistenceDouble(registration: nil), provider: NilEncrypterProvider())
        let identifier = generator.broadcastPayload(date: Date())

        XCTAssertNil(identifier)
    }

    func test_it_provides_the_encrypted_result_once_given_sonar_id_and_server_public_key() {
        let persistence = PersistenceDouble(registration: registration)
        let provider = ConcreteBroadcastIdEncrypterProvider(persistence: persistence)
        generator = SonarBroadcastPayloadGenerator(storage: storage, persistence: persistence, provider: provider)
        
        let payload = generator.broadcastPayload()

        XCTAssertNotNil(payload)
    }

    func test_generates_and_caches_broadcastId_when_none_cached() {
        let today = Date()
        let todayMidday = utcCalendar.date(bySetting: .hour, value: 12, of: today)!
        let tomorrowMidnightUTC = utcCalendar.startOfDay(for: utcCalendar.date(byAdding: .day, value: 1, to: today)!)

        storage = MockBroadcastRotationKeyStorage(
            stubbedKey: nil,
            stubbedBroadcastId: nil,
            stubbedBroadcastDate: nil)
        let persistence = PersistenceDouble(registration: registration)
        generator = SonarBroadcastPayloadGenerator(storage: storage, persistence: persistence, provider: MockEncrypterProvider(encrypter: encrypter))
        
        let payload = generator.broadcastPayload(date: todayMidday)
        
        XCTAssertEqual(encrypter.startDate, todayMidday)
        XCTAssertEqual(encrypter.endDate, tomorrowMidnightUTC)
        XCTAssertEqual(encrypter.callCount, 1)
        XCTAssertNotNil(payload)
        XCTAssertEqual(storage.savedBroadcastId, MockEncrypter.broadcastId)
        XCTAssertEqual(storage.savedBroadcastIdDate, todayMidday)
    }
    
    func test_returns_cached_broadcastId_when_cache_is_fresh() {
        let freshBroadcastId = "this is a broadcastId".data(using: .utf8)
        let today = Date()
        let todayMidday = utcCalendar.date(bySetting: .hour, value: 12, of: today)!
        storage = MockBroadcastRotationKeyStorage(
            stubbedKey: nil,
            stubbedBroadcastId: freshBroadcastId,
            stubbedBroadcastDate: todayMidday)
        let persistence = PersistenceDouble(registration: registration)
        generator = SonarBroadcastPayloadGenerator(storage: storage, persistence: persistence, provider: MockEncrypterProvider(encrypter: encrypter))

        let payload = generator.broadcastPayload(date: todayMidday)
        
        XCTAssertEqual(encrypter.callCount, 0)
        XCTAssertEqual(payload?.cryptogram, freshBroadcastId)
        XCTAssertNil(storage.savedBroadcastId)
        XCTAssertNil(storage.savedBroadcastIdDate)
    }
    
    func test_caches_and_returns_new_broadcastId_when_cache_is_stale() {
        let staleBroadcastId = "this is a broadcastId".data(using: .utf8)
        let today = Date()
        let todayMidday = utcCalendar.date(bySetting: .hour, value: 12, of: today)!
        let yesterdayMidday = utcCalendar.startOfDay(for: utcCalendar.date(byAdding: .day, value: -1, to: today)!)
        storage = MockBroadcastRotationKeyStorage(
            stubbedKey: nil,
            stubbedBroadcastId: staleBroadcastId,
            stubbedBroadcastDate: yesterdayMidday)
        let persistence = PersistenceDouble(registration: registration)
        generator = SonarBroadcastPayloadGenerator(storage: storage, persistence: persistence, provider: MockEncrypterProvider(encrypter: encrypter))

        let payload = generator.broadcastPayload(date: todayMidday)
        
        XCTAssertEqual(encrypter.startDate, todayMidday)
        XCTAssertEqual(encrypter.endDate, today.followingMidnightUTC)
        XCTAssertEqual(encrypter.callCount, 1)
        XCTAssertNotEqual(payload?.cryptogram, staleBroadcastId)
        XCTAssertEqual(storage.savedBroadcastId, MockEncrypter.broadcastId)
        XCTAssertEqual(storage.savedBroadcastIdDate, todayMidday)
    }

}

fileprivate class MockBroadcastRotationKeyStorage: BroadcastRotationKeyStorage {
    
    var stubbedKey: SecKey?
    var stubbedBroadcastId: Data?
    var stubbedBroadcastDate: Date?
    
    var savedBroadcastId: Data?
    var savedBroadcastIdDate: Date?

    init(stubbedKey: SecKey? = nil, stubbedBroadcastId: Data? = nil, stubbedBroadcastDate: Date? = nil) {
        self.stubbedKey = stubbedKey
        self.stubbedBroadcastId = stubbedBroadcastId
        self.stubbedBroadcastDate = stubbedBroadcastDate
    }

    func save(publicKey: SecKey) throws {
    }

    func read() -> SecKey? {
        return stubbedKey
    }

    func clear() throws {
    }
    
    func save(broadcastId: Data, date: Date) {
        savedBroadcastId = broadcastId
        savedBroadcastIdDate = date
    }
    
    func readBroadcastId() -> (Data, Date)? {
        guard let broadcastId = self.stubbedBroadcastId, let date = self.stubbedBroadcastDate else {
            return nil
        }
        return (broadcastId, date)
    }
}

class MockEncrypter: BroadcastIdEncrypter {
    static let broadcastId = "mock encrypter output".data(using: .utf8)!
    var startDate: Date?
    var endDate: Date?
    var callCount = 0
    func broadcastId(from startDate: Date, until endDate: Date) -> Data {
        self.startDate = startDate
        self.endDate = endDate
        callCount += 1
        return MockEncrypter.broadcastId
    }
}

struct MockEncrypterProvider: BroadcastIdEncrypterProvider {
    
    let encrypter: BroadcastIdEncrypter
    
    func getEncrypter() -> BroadcastIdEncrypter? {
        return encrypter
    }
}
