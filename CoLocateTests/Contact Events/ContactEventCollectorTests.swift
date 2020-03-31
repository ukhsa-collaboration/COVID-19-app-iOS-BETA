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

    func testRecorderRecordsContactEventOnDisconnect() throws {
        collector.btleListener(listener, didConnect: peripheral1)
        collector.btleListener(listener, didFindSonarId: sonarId1, forPeripheral: peripheral1)
        collector.btleListener(listener, didDisconnectPeripheral: peripheral1, error: nil)
        
        XCTAssertEqual(recorder.contactEvents.count, 1)
        XCTAssertEqual(recorder.contactEvents.first?.remoteContactId, sonarId1)
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
