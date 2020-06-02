//
//  ConcreteBroadcastIdGeneratorTests.swift
//  SonarTests
//
//  Created by NHSX on 10/04/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class SonarBroadcastPayloadGeneratorTests: XCTestCase {

    let registration = Registration(sonarId: UUID(uuidString: "054DDC35-0287-4247-97BE-D9A3AF012E36")!, secretKey: SecKey.sampleHMACKey, broadcastRotationKey: SecKey.sampleEllipticCurveKey)
    
    let utcCalendar: Calendar = {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()
    
    var generator: SonarBroadcastPayloadGenerator!
    var encrypter: MockEncrypter!
    var storage: MockBroadcastRotationKeyStorage!
    
    var now: Date!
    var todayMidday: Date!
    var yesterdayMidday: Date!
    var tomorrowMidnightUTC: Date!
    var todayAlmostMidnightUTC: Date!
    var tomorrowJustAfterMidnightUTC: Date!

    override func setUp() {
        now = Date()
        todayMidday = utcCalendar.date(bySettingHour: 12, minute: 0, second: 0, of: now)!
        yesterdayMidday = utcCalendar.startOfDay(for: utcCalendar.date(byAdding: .day, value: -1, to: todayMidday)!)
        tomorrowMidnightUTC = utcCalendar.startOfDay(for: utcCalendar.date(byAdding: .day, value: 1, to: now)!)
        todayAlmostMidnightUTC = utcCalendar.date(byAdding: .second, value: -1, to: tomorrowMidnightUTC)
        tomorrowJustAfterMidnightUTC = utcCalendar.date(byAdding: .second, value: 1, to: tomorrowMidnightUTC)
        
//        You can test this by setting the TZ variable in the Xcode scheme "Run" configuration to a zone which
//        is a different day to where you're running ("Pacific/Auckland" is useful, but you've got to be actually
//        running it in the afternoon if you're in a central European/UTC timezone to expose the bug we
//        originally had)
//        print("I think now is       \(now!) with zone \(Calendar.current.timeZone)")
//        print("todayMidday:         \(todayMidday!)")
//        print("yesterdayMidday:     \(yesterdayMidday!)")
//        print("tomorrowMidnightUTC: \(tomorrowMidnightUTC!)")

        storage = MockBroadcastRotationKeyStorage(stubbedKey: nil)
        encrypter = MockEncrypter()
    }

    func test_returns_nil_when_registration_is_nil() {
        generator = SonarBroadcastPayloadGenerator(storage: storage, persistence: PersistenceDouble(registration: nil), encrypter: encrypter)
        let identifier = generator.broadcastPayload(date: Date())

        XCTAssertNil(identifier)
    }

    func test_it_provides_the_encrypted_result_once_given_sonar_id_and_server_public_key() {
        let persistence = PersistenceDouble(registration: registration)
        generator = SonarBroadcastPayloadGenerator(storage: storage, persistence: persistence, encrypter: encrypter)
        
        let payload = generator.broadcastPayload()

        XCTAssertNotNil(payload)
    }

    func test_generates_and_caches_broadcastId_when_none_cached() throws {
        storage = MockBroadcastRotationKeyStorage(
            stubbedKey: nil,
            stubbedBroadcastId: nil,
            stubbedBroadcastDate: nil)
        let persistence = PersistenceDouble(registration: registration)
        generator = SonarBroadcastPayloadGenerator(storage: storage, persistence: persistence, encrypter: encrypter)
        
        let payload = generator.broadcastPayload(date: todayMidday)
        
        XCTAssertEqual(encrypter.startDate, todayMidday)
        XCTAssertEqual(encrypter.endDate, tomorrowMidnightUTC)
        XCTAssertEqual(encrypter.callCount, 1)
        XCTAssertNotNil(payload)
        XCTAssertEqual(storage.savedBroadcastId, MockEncrypter.broadcastId)
        XCTAssertEqual(storage.savedBroadcastIdDate, todayMidday)
    }
    
    func test_cachedNow_currentDate_almostMidnight_uses_cache() throws {
        try assertCacheFresh(broadcastIdCreationDate: todayMidday, currentDate: todayAlmostMidnightUTC)
    }
    
    func test_cachedNow_currentDate_now_uses_cache() throws {
        try assertCacheFresh(broadcastIdCreationDate: todayMidday, currentDate: todayMidday)
    }
    
    func assertCacheFresh(broadcastIdCreationDate: Date, currentDate: Date, file: StaticString = #file, line: UInt = #line) throws {
        let freshBroadcastId = "this is a broadcastId".data(using: .utf8)

        storage = MockBroadcastRotationKeyStorage(
            stubbedKey: nil,
            stubbedBroadcastId: freshBroadcastId,
            stubbedBroadcastDate: broadcastIdCreationDate)
        let persistence = PersistenceDouble(registration: registration)
        generator = SonarBroadcastPayloadGenerator(storage: storage, persistence: persistence, encrypter: encrypter)

        let payload = generator.broadcastPayload(date: currentDate)
        
        XCTAssertEqual(encrypter.callCount, 0, file: file, line: line)
        XCTAssertEqual(payload?.cryptogram, freshBroadcastId, file: file, line: line)
        XCTAssertNil(storage.savedBroadcastId, file: file, line: line)
        XCTAssertNil(storage.savedBroadcastIdDate, file: file, line: line)
    }

    func test_cached_yesterday_currentDate_midday_regenerates_broadcastId() throws {
        try assertStaleCacheWith(broadcastIdCreationDate: yesterdayMidday, currentDate: todayMidday)
    }
    
    func test_cached_now_currentDate_midnight_regenerates_broadcastId() throws {
        try assertStaleCacheWith(broadcastIdCreationDate: now, currentDate: tomorrowMidnightUTC)
    }
    
    func test_cached_now_currentDate_just_after_midnight_regenerates_broadcastId() throws {
        try assertStaleCacheWith(broadcastIdCreationDate: now, currentDate: tomorrowJustAfterMidnightUTC)
    }
    
    func assertStaleCacheWith(broadcastIdCreationDate: Date, currentDate: Date, file: StaticString = #file, line: UInt = #line) throws {
        let staleBroadcastId = "this is a broadcastId".data(using: .utf8)

        storage = MockBroadcastRotationKeyStorage(
            stubbedKey: nil,
            stubbedBroadcastId: staleBroadcastId,
            stubbedBroadcastDate: broadcastIdCreationDate)
        let persistence = PersistenceDouble(registration: registration)
        generator = SonarBroadcastPayloadGenerator(storage: storage, persistence: persistence, encrypter: encrypter)

        let payload = generator.broadcastPayload(date: currentDate)
        
        XCTAssertEqual(encrypter.startDate, currentDate, file: file, line: line)
        XCTAssertEqual(encrypter.endDate, currentDate.followingMidnightUTC, file: file, line: line)
        XCTAssertEqual(encrypter.callCount, 1, file: file, line: line)
        XCTAssertEqual(payload?.cryptogram, MockEncrypter.broadcastId, file: file, line: line)
        XCTAssertEqual(storage.savedBroadcastId, MockEncrypter.broadcastId, file: file, line: line)
        XCTAssertEqual(storage.savedBroadcastIdDate, currentDate, file: file, line: line)
    }

}

class MockBroadcastRotationKeyStorage: BroadcastRotationKeyStorage {
    
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
    func broadcastId(secKey: SecKey, sonarId: UUID, from startDate: Date, until endDate: Date) -> Data {
        self.startDate = startDate
        self.endDate = endDate
        callCount += 1
        return MockEncrypter.broadcastId
    }
}
