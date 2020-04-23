//
//  AppDelegateTest.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class AppDelegateTest: XCTestCase {

    var nursery: MockBluetoothNursery!
    
    var appDelegate: AppDelegate!
    
    override func setUp() {
        nursery = MockBluetoothNursery()
        
        appDelegate = AppDelegate()
        appDelegate.bluetoothNursery = nursery
    }

    func testFirstAppLaunchDoesNothing() throws {
        _ = appDelegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)
        
        XCTAssertFalse(nursery.startListenerCalled)
        XCTAssertFalse(nursery.startBroadcasterCalled)
    }
    
    func testStartingWithRegistrationAfterForceQuitStartsListenerAndBroadcaster() {
//        appDelegate.persistence = PersistenceDouble(registration: Registration())
//
//        appDelegate.bluetoothNursery
    }

}

class MockBluetoothNursery: BluetoothNursery {
    
    var contactEventRepository: ContactEventRepository = DummyContactEventRepository()
    
    var contactEventPersister: ContactEventPersister = DummyContactEventPersister()
    
    var startBroadcasterCalled = false
    var startListenerCalled = false
    
    func startBroadcaster(stateDelegate: BTLEBroadcasterStateDelegate?) {
        self.startBroadcasterCalled = true
    }
    
    func startListener(stateDelegate: BTLEListenerStateDelegate?) {
        self.startListenerCalled = true
    }
    
}

class DummyContactEventRepository: ContactEventRepository {
    var contactEvents: [ContactEvent] = []
    func reset() {
    }
    func removeExpiredContactEvents(ttl: Double) {
    }
    
    func btleListener(_ listener: BTLEListener, didFind sonarId: Data, forPeripheral peripheral: BTLEPeripheral) {
    }
    func btleListener(_ listener: BTLEListener, didReadRSSI RSSI: Int, forPeripheral peripheral: BTLEPeripheral) {
    }
}

class DummyContactEventPersister: ContactEventPersister {
    var items: [UUID: ContactEvent] = [:]
    func reset() {
    }
}
