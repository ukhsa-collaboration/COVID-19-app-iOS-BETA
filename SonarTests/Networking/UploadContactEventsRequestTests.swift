//
//  PatchContactIdentifierRequest.swift
//  SonarTests
//
//  Created by NHSX on 19.03.20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class UploadContactEventsRequestTests: XCTestCase {

    let sonarId = UUID(uuidString: "E9D7F53C-DE9C-46A2-961E-8302DC39558A")!
    let dummyKey = SecKey.sampleHMACKey

    let payload1 = IncomingBroadcastPayload.sample1
    let payload2 = IncomingBroadcastPayload.sample2
    let payload3 = IncomingBroadcastPayload.sample3

    let timestamp1 = Date(timeIntervalSince1970: 0)
    let timestamp2 = Date(timeIntervalSince1970: 10)
    let timestamp3 = Date(timeIntervalSince1970: 100)

    let rssi1: Int8 = -11
    let rssi2: Int8 = -1
    let rssi3: Int8 = -21
    
    let rssiValues1: [Int8] = [-11, -12, -13]
    let rssiValues2: [Int8] = [-21, -22, -23]
    let rssiValues3: [Int8] = [-31, -32, -33]
    
    var rssiTimestamps1: [Date]!
    var rssiTimestamps2: [Date]!
    var rssiTimestamps3: [Date]!

    var contactEvents: [ContactEvent]!

    var request: UploadContactEventsRequest!
    
    override func setUp() {
        rssiTimestamps1 = [timestamp1 + 11, timestamp1 + 12, timestamp1 + 14]
        rssiTimestamps2 = [timestamp2 + 12, timestamp2 + 14, timestamp2 + 17]
        rssiTimestamps3 = [timestamp3 + 13, timestamp3 + 16, timestamp3 + 20]

        contactEvents = [
            ContactEvent(broadcastPayload: payload1, txPower: 11, timestamp: timestamp1, rssiValues: rssiValues1, rssiTimestamps: rssiTimestamps1, duration: 0),
            ContactEvent(broadcastPayload: payload2, txPower: 22, timestamp: timestamp2, rssiValues: rssiValues2, rssiTimestamps: rssiTimestamps2, duration: 0),
            ContactEvent(broadcastPayload: payload3, txPower: 33, timestamp: timestamp3, rssiValues: rssiValues3, rssiTimestamps: rssiTimestamps3, duration: 0)
        ]

        let registration = Registration(id: sonarId, secretKey: dummyKey, broadcastRotationKey: SecKey.sampleEllipticCurveKey)
        request = UploadContactEventsRequest(
            registration: registration,
            symptomsTimestamp: Date(timeIntervalSince1970: 100),
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

    func testBody() throws {
        // We deliberately assert against the rendered json here as we want to be alerted if
        // a rename changes our json keys
        let expectedBody =
"""
{
  "contactEvents" : [
    {
      "rssiIntervals" : [
        11, 1, 2
      ],
      "txPowerInProtocol" : 0,
      "hmacSignature" : "AAAAAAAAAAAAAAAAAAAAAA==",
      "transmissionTime" : 0,
      "rssiValues" : [
        -11, -12, -13
      ],
      "duration" : 0,
      "countryCode" : 1,
      "encryptedRemoteContactId" : "AAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==",
      "txPowerAdvertised" : 11,
      "timestamp" : 0
    },
    {
      "rssiIntervals" : [
        12, 2, 3
      ],
      "txPowerInProtocol" : 0,
      "hmacSignature" : "AAAAAAAAAAAAAAAAAAAAAA==",
      "transmissionTime" : 0,
      "rssiValues" : [
        -21, -22, -23
      ],
      "duration" : 0,
      "countryCode" : 2,
      "encryptedRemoteContactId" : "AAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==",
      "txPowerAdvertised" : 22,
      "timestamp" : 10
    },
    {
      "rssiIntervals" : [
        13, 3, 4
      ],
      "txPowerInProtocol" : 0,
      "hmacSignature" : "AAAAAAAAAAAAAAAAAAAAAA==",
      "transmissionTime" : 0,
      "rssiValues" : [
        -31, -32, -33
      ],
      "duration" : 0,
      "countryCode" : 3,
      "encryptedRemoteContactId" : "AAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==",
      "txPowerAdvertised" : 33,
      "timestamp" : 100
    }
  ],
  "symptomsTimestamp" : "1970-01-01T00:01:40Z"
}
""".removingAllWhitespacesAndNewlines
        XCTAssertEqual(String(data: request.body!, encoding: .utf8), expectedBody)
    }
}

extension StringProtocol where Self: RangeReplaceableCollection {
    var removingAllWhitespacesAndNewlines: Self {
        return filter { !$0.isNewline && !$0.isWhitespace }
    }
}
