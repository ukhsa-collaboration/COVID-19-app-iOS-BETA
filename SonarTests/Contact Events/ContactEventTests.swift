//
//  ContactEventTests.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

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
    
    func testSerializesAndDeserializes() throws {
        var toSave = ContactEvent(
            timestamp: Date(),
            rssiValues: [-42],
            rssiIntervals: [123],
            duration: 456.0
        )
        toSave.broadcastPayload = IncomingBroadcastPayload.sample1
        toSave.txPower = 123
        let data = try JSONEncoder().encode(toSave)
        let decoded = try JSONDecoder().decode(ContactEvent.self, from: data)
        
        XCTAssertEqual(decoded, toSave)
    }
    
    func testDecodesPreviousVersion() throws {
        let previous = PreviousSerializationFormat(
            broadcastPayload: IncomingBroadcastPayload.sample1,
            timestamp: Date(),
            rssiValues: [-42],
            rssiIntervals: [123],
            duration: 456.0
        )
        let data = try JSONEncoder().encode(previous)
        let decoded = try JSONDecoder().decode(ContactEvent.self, from: data)
        
        XCTAssertEqual(decoded.broadcastPayload, previous.broadcastPayload)
        XCTAssertEqual(decoded.timestamp, previous.timestamp)
        XCTAssertEqual(decoded.rssiValues, previous.rssiValues)
        XCTAssertEqual(decoded.duration, previous.duration)
    }
}

// As of v1.0.1, build 341
private struct PreviousSerializationFormat: Codable {
    var broadcastPayload: IncomingBroadcastPayload? = nil
    var timestamp: Date = Date()
    var rssiValues: [Int8] = []
    var rssiIntervals: [TimeInterval] = []
    var duration: TimeInterval = 0
}
