//
//  BluetoothStateObserverTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import CoreBluetooth
import XCTest
@testable import CoLocate

class BluetoothStateObserverTests: TestCase {
    
    func testNotifyOnStateChanges_notifiesWithCurrentState() {
        let observer = BluetoothStateObserver(initialState: .unknown)
        var receivedState: CBManagerState? = nil
        observer.notifyOnStateChanges { state in
            receivedState = state
            return .keepObserving
        }
        
        XCTAssertEqual(receivedState, .unknown)
    }

    func testNotifyOnStateChanges_notifiesOnEveryChange() {
        let observer = BluetoothStateObserver(initialState: .unknown)
        var receivedState: CBManagerState? = nil
        observer.notifyOnStateChanges { state in
            receivedState = state
            return .keepObserving
        }
        
        observer.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOff)
        XCTAssertEqual(receivedState, .poweredOff)
        
        observer.btleListener(BTLEListenerDouble(), didUpdateState: .unknown)
        XCTAssertEqual(receivedState, .unknown)
        
        observer.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOn)
        XCTAssertEqual(receivedState, .poweredOn)
    }
    
    func testNotifyOnStateChange_doesNotNotifyAfterRemoval() {
        let observer = BluetoothStateObserver(initialState: .unknown)
        var removedCallCount = 0
        var otherCallCount = 0
        observer.notifyOnStateChanges { state in
           removedCallCount += 1
           return .stopObserving
        }
        observer.notifyOnStateChanges { state in
            otherCallCount += 1
            return .keepObserving
        }
        
        observer.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOff)
        observer.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOn)

        XCTAssertEqual(removedCallCount, 1)
        XCTAssertEqual(otherCallCount, 3)
    }
}
