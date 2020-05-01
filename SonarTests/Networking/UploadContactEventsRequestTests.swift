//
//  PatchContactIdentifierRequest.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class UploadContactEventsRequestTests: XCTestCase {

    let sonarId = UUID(uuidString: "E9D7F53C-DE9C-46A2-961E-8302DC39558A")!
    let dummyKey = "this-is-a-symmetric-key-trust-me".data(using: .utf8)!

    let payload1 = IncomingBroadcastPayload.sample1
    let payload2 = IncomingBroadcastPayload.sample2
    let payload3 = IncomingBroadcastPayload.sample3

    let timestamp1 = Date(timeIntervalSince1970: 0)
    let timestamp2 = Date(timeIntervalSince1970: 10)
    let timestamp3 = Date(timeIntervalSince1970: 100)

    let rssi1: Int8 = -11
    let rssi2: Int8 = -1
    let rssi3: Int8 = -21

    var contactEvents: [ContactEvent]!

    var request: UploadContactEventsRequest!
    
    override func setUp() {
        contactEvents = [
            ContactEvent(broadcastPayload: payload1, timestamp: timestamp1, rssiValues: [rssi1], rssiIntervals: [10], duration: 0),
            ContactEvent(broadcastPayload: payload2, timestamp: timestamp2, rssiValues: [rssi2], rssiIntervals: [20], duration: 0),
            ContactEvent(broadcastPayload: payload3, timestamp: timestamp3, rssiValues: [rssi3], rssiIntervals: [30], duration: 0)
        ]

        let registration = Registration(id: sonarId, secretKey: dummyKey, broadcastRotationKey: SecKey.sampleEllipticCurveKey)
        request = UploadContactEventsRequest(
            registration: registration,
            symptomsTimestamp: Date(),
            contactEvents: contactEvents
        )
    }

    func testMethod() {
        XCTAssertTrue(request.isMethodPATCH)
    }

    func testPath() {
        XCTAssertEqual(request.urlable, .path("/api/residents/\(sonarId.uuidString)"))
    }
    
    func testHeaders() {
        XCTAssertEqual(request.headers["Accept"], "application/json")
        XCTAssertEqual(request.headers["Content-Type"], "application/json")
    }

    /*
    func testBody() throws {
        let expectedBody =
"""
{
  "contactEvents" : [
    {
      "countryCode" : 1,
      "duration" : 0,
      "encryptedRemoteContactId" : "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==",
      "hmacSignature" : "AAAAAAAAAAAAAAAAAAAAAA==",
      "rssiIntervals" : [
        10
      ],
      "rssiValues" : [
        -11
      ],
      "timestamp" : 0,
      "transmissionTime" : 0,
      "txPowerAdvertised" : 0,
      "txPowerInProtocol" : 0
    },
    {
      "countryCode" : 2,
      "duration" : 0,
      "encryptedRemoteContactId" : "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==",
      "hmacSignature" : "AAAAAAAAAAAAAAAAAAAAAA==",
      "rssiIntervals" : [
        20
      ],
      "rssiValues" : [
        -1
      ],
      "timestamp" : 10,
      "transmissionTime" : 0,
      "txPowerAdvertised" : 0,
      "txPowerInProtocol" : 0
    },
    {
      "countryCode" : 3,
      "duration" : 0,
      "encryptedRemoteContactId" : "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==",
      "hmacSignature" : "AAAAAAAAAAAAAAAAAAAAAA==",
      "rssiIntervals" : [
        30
      ],
      "rssiValues" : [
        -21
      ],
      "timestamp" : 100,
      "transmissionTime" : 0,
      "txPowerAdvertised" : 0,
      "txPowerInProtocol" : 0
    }
  ],
  "symptomsTimestamp" : "2020-05-01T13:33:40Z"
}
""".removingAllWhitespacesAndNewlines
        XCTAssertEqual(String(data: request.body!, encoding: .utf8), expectedBody)
    }

*/
}

extension StringProtocol where Self: RangeReplaceableCollection {
    var removingAllWhitespacesAndNewlines: Self {
        return filter { !$0.isNewline && !$0.isWhitespace }
    }
    mutating func removeAllWhitespacesAndNewlines() {
        removeAll { $0.isNewline || $0.isWhitespace }
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

/*
{\"contactEvents\":[{\"rssiIntervals\":[10],\"txPowerInProtocol\":0,\"hmacSignature\":\"AAAAAAAAAAAAAAAAAAAAAA==\",\"transmissionTime\":0,\"rssiValues\":[-11],\"duration\":0,\"countryCode\":1,\"encryptedRemoteContactId\":\"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==\",\"txPowerAdvertised\":0,\"timestamp\":0},{\"rssiIntervals\":[20],\"txPowerInProtocol\":0,\"hmacSignature\":\"AAAAAAAAAAAAAAAAAAAAAA==\",\"transmissionTime\":0,\"rssiValues\":[-1],\"duration\":0,\"countryCode\":2,\"encryptedRemoteContactId\":\"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==\",\"txPowerAdvertised\":0,\"timestamp\":10},{\"rssiIntervals\":[30],\"txPowerInProtocol\":0,\"hmacSignature\":\"AAAAAAAAAAAAAAAAAAAAAA==\",\"transmissionTime\":0,\"rssiValues\":[-21],\"duration\":0,\"countryCode\":3,\"encryptedRemoteContactId\":\"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==\",\"txPowerAdvertised\":0,\"timestamp\":100}],\"symptomsTimestamp\":\"2020-05-01T16:01:39Z\"}
 
 {\"contactEvents\":[{\"countryCode\":1,\"duration\":0,\"encryptedRemoteContactId\":\"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==\",\"hmacSignature\":\"AAAAAAAAAAAAAAAAAAAAAA==\",\"rssiIntervals\":[10],\"rssiValues\":[-11],\"timestamp\":0,\"transmissionTime\":0,\"txPowerAdvertised\":0,\"txPowerInProtocol\":0},{\"countryCode\":2,\"duration\":0,\"encryptedRemoteContactId\":\"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==\",\"hmacSignature\":\"AAAAAAAAAAAAAAAAAAAAAA==\",\"rssiIntervals\":[20],\"rssiValues\":[-1],\"timestamp\":10,\"transmissionTime\":0,\"txPowerAdvertised\":0,\"txPowerInProtocol\":0},{\"countryCode\":3,\"duration\":0,\"encryptedRemoteContactId\":\"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==\",\"hmacSignature\":\"AAAAAAAAAAAAAAAAAAAAAA==\",\"rssiIntervals\":[30],\"rssiValues\":[-21],\"timestamp\":100,\"transmissionTime\":0,\"txPowerAdvertised\":0,\"txPowerInProtocol\":0}],\"symptomsTimestamp\":\"2020-05-01T13:33:40Z\"}
 */
