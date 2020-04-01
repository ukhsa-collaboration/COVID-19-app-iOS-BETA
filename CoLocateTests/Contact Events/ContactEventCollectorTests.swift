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
    
    let sonarId1 = UUID()
    let sonarId2 = UUID()
    let sonarId3 = UUID()
    
    var listener: BTLEListener!
    var recorder: ContactEventRecorder!
    var collector: ContactEventCollector!

    override func setUp() {
        listener = BTLEListener()
        recorder = TestContactEventRecorder()
        collector = ContactEventCollector(contactEventRecorder: recorder)
    }

    func testRecordsContactEventOnDisconnect() {
        collector.btleListener(listener, didConnect: peripheral1)
        collector.btleListener(listener, didFindSonarId: sonarId1, forPeripheral: peripheral1)
        collector.btleListener(listener, didDisconnect: peripheral1, error: nil)
        
        XCTAssertEqual(recorder.contactEvents.count, 1)
        XCTAssertEqual(recorder.contactEvents.first?.sonarId, sonarId1)
    }
    
    func testDoesNotRecordContactEventForIncompleteRecordMissingSonarId() {
        collector.btleListener(listener, didConnect: peripheral1)
        collector.btleListener(listener, didDisconnect: peripheral1, error: nil)
        
        XCTAssertEqual(recorder.contactEvents.count, 0)
    }
    
    func testRequestsRSSIForConnectedPeripheral() {
        collector.btleListener(listener, didConnect: peripheral1)
        
        XCTAssertTrue(collector.btleListener(listener, shouldReadRSSIFor: peripheral1))
    }
    
    func testDoesNotRequestRSSIForDisconnectedPeripheral() {
        collector.btleListener(listener, didConnect: peripheral1)
        collector.btleListener(listener, didDisconnect: peripheral1, error: nil)

        XCTAssertFalse(collector.btleListener(listener, shouldReadRSSIFor: peripheral1))
    }
    
    func testDoesNotRequestRSSIForUnknownPeripheral() {
        collector.btleListener(listener, didConnect: peripheral1)
        
        XCTAssertFalse(collector.btleListener(listener, shouldReadRSSIFor: peripheral2))
    }
    
    func testRecordsRSSIValuesAgainstCorrectPeripheral() {
        collector.btleListener(listener, didConnect: peripheral1)
        collector.btleListener(listener, didFindSonarId: sonarId1, forPeripheral: peripheral1)
        collector.btleListener(listener, didConnect: peripheral2)
        collector.btleListener(listener, didFindSonarId: sonarId2, forPeripheral: peripheral2)
        collector.btleListener(listener, didConnect: peripheral3)
        collector.btleListener(listener, didFindSonarId: sonarId3, forPeripheral: peripheral3)

        collector.btleListener(listener, didReadRSSI: 21, forPeripheral: peripheral2)
        collector.btleListener(listener, didReadRSSI: 11, forPeripheral: peripheral1)
        collector.btleListener(listener, didReadRSSI: 31, forPeripheral: peripheral3)
        collector.btleListener(listener, didReadRSSI: 22, forPeripheral: peripheral2)
        collector.btleListener(listener, didReadRSSI: 32, forPeripheral: peripheral3)
        collector.btleListener(listener, didReadRSSI: 23, forPeripheral: peripheral2)
        collector.btleListener(listener, didReadRSSI: 12, forPeripheral: peripheral1)
        collector.btleListener(listener, didReadRSSI: 13, forPeripheral: peripheral1)
        collector.btleListener(listener, didReadRSSI: 33, forPeripheral: peripheral3)
        
        XCTAssertEqual(collector.connectedPeripherals[peripheral1.identifier]?.rssiSamples, [11, 12, 13])
        XCTAssertEqual(collector.connectedPeripherals[peripheral2.identifier]?.rssiSamples, [21, 22, 23])
        XCTAssertEqual(collector.connectedPeripherals[peripheral3.identifier]?.rssiSamples, [31, 32, 33])
    }

}

struct TestPeripheral: BTLEPeripheral {
    let identifier: UUID
}

class TestContactEventRecorder: ContactEventRecorder {

    var contactEvents: [ContactEvent] = []
    
    func record(_ contactEvent: ContactEvent) {
        contactEvents.append(contactEvent)
    }
    
    func reset() {
        contactEvents = []
    }
    
}
