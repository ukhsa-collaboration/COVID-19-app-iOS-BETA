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
    
    var request: PatchContactEventsRequest!
    
    override func setUp() {
        let contactEvents = [
            ContactEvent(uuid: deviceId1),
            ContactEvent(uuid: deviceId2),
            ContactEvent(uuid: deviceId3)
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
        XCTAssertEqual(contactEvents[1].uuid, deviceId2)
        XCTAssertEqual(contactEvents[2].uuid, deviceId3)
    }

}
