//
//  ContactEventTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class ContactEventTests: XCTestCase {
    
    let time0 = Date(timeIntervalSince1970: 0)
    let time1 = Date(timeIntervalSince1970: 101)
    let time2 = Date(timeIntervalSince1970: 210)
    let time3 = Date(timeIntervalSince1970: 333)

    func testAddingRSSIValuesSetsIntervalsAndDuration() {
        var contactEvent = ContactEvent(timestamp: time0)
        contactEvent.recordRSSI(42, timestamp: time1)
        contactEvent.recordRSSI(17, timestamp: time2)
        contactEvent.recordRSSI(4, timestamp: time3)
        
        XCTAssertEqual(contactEvent.duration, 333)
        
        XCTAssertEqual(contactEvent.rssiIntervals.count, 3)
        XCTAssertEqual(contactEvent.rssiIntervals[0], 101)
        XCTAssertEqual(contactEvent.rssiIntervals[1], 109)
        XCTAssertEqual(contactEvent.rssiIntervals[2], 123)
    }
}

struct SonarIdUuid: Decodable {
    let sonarId: Data
}
