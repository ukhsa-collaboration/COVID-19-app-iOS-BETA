//
//  PatchContactIdentifierRequest.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class PatchContactEventsRequestTests: XCTestCase {

    let anonymousId = UUID(uuidString: "E9D7F53C-DE9C-46A2-961E-8302DC39558A")!
    let dummyKey = "this-is-a-symmetric-key-trust-me".data(using: .utf8)!

    let broadcastId1 = Data(base64Encoded: "62D583B3052C4CF9808C0B96080F0DB8")!
    let broadcastId2 = Data(base64Encoded: "AA94DF1440774D6B9712D90861D8BDE7")!
    let broadcastId3 = Data(base64Encoded: "2F13DB8A7A5E47C991D004F6AE19D869")!

    let timestamp1 = Date(timeIntervalSince1970: 0)
    let timestamp2 = Date(timeIntervalSince1970: 10)
    let timestamp3 = Date(timeIntervalSince1970: 100)

    let rssi1 = -11
    let rssi2 = -1
    let rssi3 = -21

    var contactEvents: [ContactEvent]!

    var request: PatchContactEventsRequest!
    
    override func setUp() {
        contactEvents = [
            ContactEvent(encryptedRemoteContactId: broadcastId1, timestamp: timestamp1, rssiValues: [rssi1], rssiIntervals: [10], duration: 0),
            ContactEvent(encryptedRemoteContactId: broadcastId2, timestamp: timestamp2, rssiValues: [rssi2], rssiIntervals: [20], duration: 0),
            ContactEvent(encryptedRemoteContactId: broadcastId3, timestamp: timestamp3, rssiValues: [rssi3], rssiIntervals: [30], duration: 0)
        ]

        let registration = Registration(id: anonymousId, secretKey: dummyKey, broadcastRotationKey: knownGoodECPublicKey())
        request = PatchContactEventsRequest(
            registration: registration,
            symptomsTimestamp: Date(),
            contactEvents: contactEvents
        )

        super.setUp()
    }

    func testMethod() {
        XCTAssertTrue(request.isMethodPATCH)
    }

    func testPath() {
        XCTAssertEqual(request.path, "/api/residents/\(anonymousId.uuidString)")
    }
    
    func testHeaders() {
        XCTAssertEqual(request.headers["Accept"], "application/json")
        XCTAssertEqual(request.headers["Content-Type"], "application/json")
    }

    func testData() throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let contactEvents = try decoder.decode(PatchContactEventsRequest.JSONWrapper.self, from: request.body!).contactEvents

        XCTAssertEqual(contactEvents.count, 3)
        XCTAssertEqual(contactEvents[0].encryptedRemoteContactId, broadcastId1)
        XCTAssertEqual(contactEvents[0].timestamp, timestamp1)
        XCTAssertEqual(contactEvents[0].rssiValues.first, rssi1)

        XCTAssertEqual(contactEvents[1].encryptedRemoteContactId, broadcastId2)
        XCTAssertEqual(contactEvents[1].timestamp, timestamp2)
        XCTAssertEqual(contactEvents[1].rssiValues.first, rssi2)

        XCTAssertEqual(contactEvents[2].encryptedRemoteContactId, broadcastId3)
        XCTAssertEqual(contactEvents[2].timestamp, timestamp3)
        XCTAssertEqual(contactEvents[2].rssiValues.first, rssi3)
    }

}

class RegistrationStorageDouble: SecureRegistrationStorage {
    let id: UUID?
    let key: Data?

    override init() {
        id = nil
        key = nil
    }

    init(id: UUID, key: Data) {
        self.id = id
        self.key = key
    }

    override func get() -> PartialRegistration? {
        guard let id = id, let key = key else { return nil }

        return PartialRegistration(id: id, secretKey: key)
    }
}
