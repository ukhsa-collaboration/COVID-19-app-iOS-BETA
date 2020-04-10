//
//  ContactEventCollectorTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate


class ContactEventCollectorTests: XCTestCase {
    
    let peripheral1 = TestPeripheral(identifier: UUID())
    let peripheral2 = TestPeripheral(identifier: UUID())
    let peripheral3 = TestPeripheral(identifier: UUID())
    
    let sonarId1 = Data(base64Encoded: "aGVsbG8K")!
    let sonarId2 = Data(base64Encoded: "Z29vZGJ5ZQo=")!
    let sonarId3 = Data(base64Encoded: "Z29vZGJ5dGUK")!
    
    var listener: BTLEListener!
    var recorder: ContactEventRecorder!
    var collector: ContactEventCollector!

    override func setUp() {
        listener = DummyBTLEListener()
        recorder = TestContactEventRecorder()
        collector = ContactEventCollector(contactEventRecorder: recorder)
    }

    func testKeepsTrackOfHowManyConnectedProperties() {
        collector.btleListener(listener, didFind:sonarId1, forPeripheral: peripheral1)

        XCTAssertEqual(1, collector._contactEventCount)
    }

    func testRecordsContactEventOnDisconnect() {
        collector.btleListener(listener, didFind: sonarId1, forPeripheral: peripheral1)
        collector.btleListener(listener, didDisconnect: peripheral1, error: nil)
        
        XCTAssertEqual(recorder.contactEvents.count, 1)
        XCTAssertEqual(recorder.contactEvents.first?.sonarId, sonarId1)
    }
    
    func testDoesNotRecordContactEventForIncompleteRecordMissingSonarId() {
        collector.btleListener(listener, didDisconnect: peripheral1, error: nil)
        
        XCTAssertEqual(recorder.contactEvents.count, 0)
    }
    
    func testRequestsRSSIForConnectedPeripheral() {
        collector.btleListener(listener, didFind: sonarId1, forPeripheral: peripheral1)
        
        XCTAssertTrue(collector.btleListener(listener, shouldReadRSSIFor: peripheral1))
    }
    
    func testDoesNotRequestRSSIForDisconnectedPeripheral() {
        collector.btleListener(listener, didDisconnect: peripheral1, error: nil)

        XCTAssertFalse(collector.btleListener(listener, shouldReadRSSIFor: peripheral1))
    }
    
    func testDoesNotRequestRSSIForUnknownPeripheral() {
        XCTAssertFalse(collector.btleListener(listener, shouldReadRSSIFor: peripheral2))
    }
    
    func testRecordsRSSIValuesAgainstCorrectPeripheral() {
        collector.btleListener(listener, didFind: sonarId1, forPeripheral: peripheral1)
        collector.btleListener(listener, didFind: sonarId2, forPeripheral: peripheral2)
        collector.btleListener(listener, didFind: sonarId3, forPeripheral: peripheral3)

        collector.btleListener(listener, didReadRSSI: 21, forPeripheral: peripheral2)
        collector.btleListener(listener, didReadRSSI: 11, forPeripheral: peripheral1)
        collector.btleListener(listener, didReadRSSI: 31, forPeripheral: peripheral3)
        collector.btleListener(listener, didReadRSSI: 22, forPeripheral: peripheral2)
        collector.btleListener(listener, didReadRSSI: 32, forPeripheral: peripheral3)
        collector.btleListener(listener, didReadRSSI: 23, forPeripheral: peripheral2)
        collector.btleListener(listener, didReadRSSI: 12, forPeripheral: peripheral1)
        collector.btleListener(listener, didReadRSSI: 13, forPeripheral: peripheral1)
        collector.btleListener(listener, didReadRSSI: 33, forPeripheral: peripheral3)
        
        XCTAssertEqual(collector.contactEvents[peripheral1.identifier]?.rssiValues, [11, 12, 13])
        XCTAssertEqual(collector.contactEvents[peripheral2.identifier]?.rssiValues, [21, 22, 23])
        XCTAssertEqual(collector.contactEvents[peripheral3.identifier]?.rssiValues, [31, 32, 33])
    }

    func test_writes_any_remaining_events_when_flush_is_called() {
        collector.btleListener(listener, didFind: sonarId1, forPeripheral: peripheral1)

        collector.flush()

        XCTAssertEqual(recorder.contactEvents.count, 1)
        XCTAssertEqual(recorder.contactEvents.first?.sonarId, sonarId1)
    }
}

struct TestPeripheral: BTLEPeripheral {
    let identifier: UUID
}

class TestContactEventRecorder: ContactEventRecorder {
    var contactEvents: [ContactEvent]

    init(_ contactEvents: [ContactEvent] = []) {
        self.contactEvents = contactEvents
    }

    func record(_ contactEvent: ContactEvent) {
        contactEvents.append(contactEvent)
    }
    
    var hasReset = false
    func reset() {
        contactEvents = []
        hasReset = true
    }
    
}

class DummyBTLEListener: BTLEListener {
    
    func start(stateDelegate: BTLEListenerStateDelegate?, delegate: BTLEListenerDelegate?) {
    }

}
