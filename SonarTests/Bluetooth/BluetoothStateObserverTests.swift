//
//  BluetoothStateObserverTests.swift
//  SonarTests
//
//  Created by NHSX on 4/23/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import CoreBluetooth
import XCTest
@testable import Sonar

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
        
        observer.listener(ListenerDouble(), didUpdateState: .poweredOff)
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
        
        observer.listener(ListenerDouble(), didUpdateState: .unknown)
        XCTAssertEqual(timesCalled, 0)

        observer.listener(ListenerDouble(), didUpdateState: .poweredOn)
        XCTAssertEqual(1, timesCalled)
        XCTAssertEqual(receivedState, .poweredOn)
        
        observer.listener(ListenerDouble(), didUpdateState: .poweredOff)
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
        
        observer.listener(ListenerDouble(), didUpdateState: .poweredOff)
        XCTAssertEqual(receivedState, .poweredOff)
        
        observer.listener(ListenerDouble(), didUpdateState: .unknown)
        XCTAssertEqual(receivedState, .unknown)
        
        observer.listener(ListenerDouble(), didUpdateState: .poweredOn)
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
        
        observer.listener(ListenerDouble(), didUpdateState: .poweredOff)
        observer.listener(ListenerDouble(), didUpdateState: .poweredOn)

        XCTAssertEqual(removedCallCount, 1)
        XCTAssertEqual(otherCallCount, 3)
    }
}
