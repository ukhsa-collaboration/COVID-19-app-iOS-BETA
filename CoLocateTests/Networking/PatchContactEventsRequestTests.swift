//
//  PatchContactIdentifierRequest.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class PatchContactEventsRequestTests: XCTestCase {

    let deviceId = UUID()
    let deviceId1 = UUID()
    let deviceId2 = UUID()
    let deviceId3 = UUID()

    let timestamp1 = URLSession.formatter.string(from: Date(timeIntervalSince1970: 0))
    let timestamp2 = URLSession.formatter.string(from: Date(timeIntervalSince1970: 10))
    let timestamp3 = URLSession.formatter.string(from: Date(timeIntervalSince1970: 100))

    let rssi1 = 1
    let rssi2 = 11
    let rssi3 = 21
    
    var request: PatchContactEventsRequest!
    
    override func setUp() {
        let contactEvents = [
            ContactEvent(uuid: deviceId1, timestamp: timestamp1, rssi: rssi1),
            ContactEvent(uuid: deviceId2, timestamp: timestamp2, rssi: rssi2),
            ContactEvent(uuid: deviceId3, timestamp: timestamp3, rssi: rssi3)
        ]
        
        request = PatchContactEventsRequest(deviceId: deviceId, contactEvents: contactEvents)
    }

    func testMethod() {
        XCTAssertTrue(request.isMethodPATCH)
    }

    func testPath() {
        XCTAssertEqual(request.path, "/api/residents/\(deviceId.uuidString)")
    }
    
    func testHeaders() {
        XCTAssertEqual(request.headers!["Accept"], "application/json")
        XCTAssertEqual(request.headers!["Content-Type"], "application/json")
    }

    func testData() {
        let contactEvents = try! JSONDecoder().decode([ContactEvent].self, from: request.data)
        
        XCTAssertEqual(contactEvents.count, 3)
        XCTAssertEqual(contactEvents[0].uuid, deviceId1)
        XCTAssertEqual(contactEvents[0].timestamp, timestamp1)
        XCTAssertEqual(contactEvents[0].rssi, rssi1)

        XCTAssertEqual(contactEvents[1].uuid, deviceId2)
        XCTAssertEqual(contactEvents[1].timestamp, timestamp2)
        XCTAssertEqual(contactEvents[1].rssi, rssi2)

        XCTAssertEqual(contactEvents[2].uuid, deviceId3)
        XCTAssertEqual(contactEvents[2].timestamp, timestamp3)
        XCTAssertEqual(contactEvents[2].rssi, rssi3)
    }

}
