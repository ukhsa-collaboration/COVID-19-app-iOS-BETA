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
        XCTAssertEqual(recorder.contactEvents.first?.remoteContactId, sonarId1)
    }
    
    func testDoesNotRecordContactEventForIncompleteRecord() {
        collector.btleListener(listener, didConnect: peripheral1)
        collector.btleListener(listener, didDisconnect: peripheral1, error: nil)
        
        XCTAssertEqual(recorder.contactEvents.count, 0)
    }
    
    func testRecorderRequestsRSSIForConnectedPeripheral() {
        collector.btleListener(listener, didConnect: peripheral1)
        
        XCTAssertTrue(collector.btleListener(listener, shouldReadRSSIFor: peripheral1))
    }
    
    func testRecorderDoesNotRequestRSSIForDisconnectedPeripheral() {
        collector.btleListener(listener, didConnect: peripheral1)
        collector.btleListener(listener, didDisconnect: peripheral1, error: nil)

        XCTAssertFalse(collector.btleListener(listener, shouldReadRSSIFor: peripheral1))
    }
    
    func testRecorderDoesNotRequestRSSIForUnknownPeripheral() {
        collector.btleListener(listener, didConnect: peripheral1)
        
        XCTAssertFalse(collector.btleListener(listener, shouldReadRSSIFor: peripheral2))
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
