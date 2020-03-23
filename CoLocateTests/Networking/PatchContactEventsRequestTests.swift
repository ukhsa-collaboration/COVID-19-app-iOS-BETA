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

    let deviceId = UUID(uuidString: "E9D7F53C-DE9C-46A2-961E-8302DC39558A")!
    let deviceId1 = UUID(uuidString: "62D583B3-052C-4CF9-808C-0B96080F0DB8")!
    let deviceId2 = UUID(uuidString: "AA94DF14-4077-4D6B-9712-D90861D8BDE7")!
    let deviceId3 = UUID(uuidString: "2F13DB8A-7A5E-47C9-91D0-04F6AE19D869")!

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
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let contactEvents = try! decoder.decode([ContactEvent].self, from: request.data)
        
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

    func testJsonSerialisedContactEvent() {
        let expectedJsonString =
"""
[{"timestamp":"1970-01-01T00:00:00Z","rssi":-11,"uuid":"62D583B3-052C-4CF9-808C-0B96080F0DB8"},{"timestamp":"1970-01-01T00:00:10Z","rssi":-1,"uuid":"AA94DF14-4077-4D6B-9712-D90861D8BDE7"},{"timestamp":"1970-01-01T00:01:40Z","rssi":-21,"uuid":"2F13DB8A-7A5E-47C9-91D0-04F6AE19D869"}]
"""
        XCTAssertEqual(String(data: request.data, encoding: .utf8)!, expectedJsonString)
    }

}
