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
    
    func testObserveUntilKnown_notifiesImmediatelyIfKnown() {
        let observer = BluetoothStateObserver(initialState: .unauthorized)
        var receivedState: CBManagerState? = nil
        var timesCalled = 0
        observer.observeUntilKnown { state in
            receivedState = state
            timesCalled += 1
        }
        
        XCTAssertEqual(1, timesCalled)
        XCTAssertEqual(receivedState, .unauthorized)
        
        observer.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOff)
        XCTAssertEqual(1, timesCalled)
    }
    
    func testObserveUntilKnown_notifiesOfFirstKnownState() {
        let observer = BluetoothStateObserver(initialState: .unknown)
        var receivedState: CBManagerState? = nil
        var timesCalled = 0
        observer.observeUntilKnown { state in
            receivedState = state
            timesCalled += 1
        }
        
        XCTAssertEqual(timesCalled, 0)
        
        observer.btleListener(BTLEListenerDouble(), didUpdateState: .unknown)
        XCTAssertEqual(timesCalled, 0)

        observer.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOn)
        XCTAssertEqual(1, timesCalled)
        XCTAssertEqual(receivedState, .poweredOn)
        
        observer.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOff)
        XCTAssertEqual(1, timesCalled)
    }
    
    func testObserve_notifiesWithCurrentState() {
        let observer = BluetoothStateObserver(initialState: .unknown)
        var receivedState: CBManagerState? = nil
        observer.observe { state in
            receivedState = state
            return .keepObserving
        }
        
        XCTAssertEqual(receivedState, .unknown)
    }

    func testObserve_notifiesOnEveryChange() {
        let observer = BluetoothStateObserver(initialState: .unknown)
        var receivedState: CBManagerState? = nil
        observer.observe { state in
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
        observer.observe { state in
           removedCallCount += 1
           return .stopObserving
        }
        observer.observe { state in
            otherCallCount += 1
            return .keepObserving
        }
        
        observer.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOff)
        observer.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOn)

        XCTAssertEqual(removedCallCount, 1)
        XCTAssertEqual(otherCallCount, 3)
    }
}
