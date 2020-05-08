//
//  ContactEventTests.swift
//  SonarTests
//
//  Created by NHSX on 13.04.20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class ContactEventTests: XCTestCase {
    
    let time0 = Date(timeIntervalSince1970: 0)
    let time1 = Date(timeIntervalSince1970: 101)
    let time2 = Date(timeIntervalSince1970: 210)
    let time3 = Date(timeIntervalSince1970: 333)

    func testAddingRSSIValuesSetsTimestampsAndDuration() {
        var contactEvent = ContactEvent(timestamp: time0)
        contactEvent.recordRSSI(42, timestamp: time1)
        contactEvent.recordRSSI(17, timestamp: time2)
        contactEvent.recordRSSI(4, timestamp: time3)
        
        XCTAssertEqual(contactEvent.duration, 333)
        
        XCTAssertEqual(contactEvent.rssiTimestamps.count, 3)
        XCTAssertEqual(contactEvent.rssiTimestamps[0], time1)
        XCTAssertEqual(contactEvent.rssiTimestamps[1], time2)
        XCTAssertEqual(contactEvent.rssiTimestamps[2], time3)
    }
    
    func testSerializesAndDeserializes() throws {
        var currentFormatContactEvent = ContactEvent(
            timestamp: Date(),
            rssiValues: [-42],
            rssiTimestamps: [time1],
            duration: 456.0
        )
        currentFormatContactEvent.broadcastPayload = IncomingBroadcastPayload.sample1
        currentFormatContactEvent.txPower = 123

        let encodedAsData = try JSONEncoder().encode(currentFormatContactEvent)
        let decodedContactEvent = try JSONDecoder().decode(ContactEvent.self, from: encodedAsData)
        
        XCTAssertEqual(decodedContactEvent, currentFormatContactEvent)
    }
    
    func testDecodesVersion1_0_1_Build341() throws {
        let previousFormatContactEvent = ContactEvent.PreviousSerializationFormats.Version1_0_1_Build341(
            broadcastPayload: IncomingBroadcastPayload.sample1,
            timestamp: Date(),
            rssiValues: [-42],
            rssiIntervals: [123],
            duration: 456.0
        )

        let encodedAsData = try JSONEncoder().encode(previousFormatContactEvent)
        let decodedContactEvent = try JSONDecoder().decode(ContactEvent.self, from: encodedAsData)
        
        XCTAssertEqual(decodedContactEvent.broadcastPayload, previousFormatContactEvent.broadcastPayload)
        XCTAssertEqual(decodedContactEvent.txPower, 0)
        XCTAssertEqual(decodedContactEvent.timestamp, previousFormatContactEvent.timestamp)
        XCTAssertEqual(decodedContactEvent.rssiValues, previousFormatContactEvent.rssiValues)
        XCTAssertEqual(decodedContactEvent.rssiTimestamps.first, previousFormatContactEvent.timestamp +  previousFormatContactEvent.rssiIntervals.first!)
        XCTAssertEqual(decodedContactEvent.duration, previousFormatContactEvent.duration)
    }

}

fileprivate extension ContactEvent {
    struct PreviousSerializationFormats {
        struct Version1_0_1_Build341: Codable {
            var broadcastPayload: IncomingBroadcastPayload? = nil
            var timestamp: Date = Date()
            var rssiValues: [Int8] = []
            var rssiIntervals: [TimeInterval] = []
            var duration: TimeInterval = 0
        }
    }
}
