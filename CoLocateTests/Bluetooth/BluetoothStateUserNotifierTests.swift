//
//  BluetoothStateObserverTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
import UIKit
import CoreBluetooth

@testable import CoLocate

class BluetoothStateUserNotifierTests: TestCase {

    let listener = TestBTLEListener()
    let mockScheduler = MockNotificationScheduler()

    let foregroundApp = DummyApp(UIApplication.State.active)
    let backgroundApp = DummyApp(UIApplication.State.background)

    var stateObserver: BluetoothStateUserNotifier!

    func test_it_does_nothing_in_the_foreground() {
        stateObserver = BluetoothStateUserNotifier(appStateReader: foregroundApp, scheduler: mockScheduler)

        stateObserver.btleListener(listener, didUpdateState: .poweredOff)

        XCTAssertEqual(0, mockScheduler.calls.count)
    }

    func test_it_creates_local_notifications_in_the_backgrouund_when_bluetooth_is_powered_off() {
        stateObserver = BluetoothStateUserNotifier(appStateReader: backgroundApp, scheduler: mockScheduler, uiQueue: QueueDouble())

        stateObserver.btleListener(listener, didUpdateState: .poweredOff)

        XCTAssertEqual(1, mockScheduler.calls.count)
        guard mockScheduler.calls.count == 1 else {
            XCTFail("Expected one call but got \(mockScheduler.calls.count)")
            return
        }

        XCTAssertTrue(("To keep yourself secure, please re-enable bluetooth", 3, "bluetooth.disabled.please") == mockScheduler.calls[0])
    }

    func test_it_does_nothing_when_bluetooth_is_powered_on() {
        stateObserver = BluetoothStateUserNotifier(appStateReader: backgroundApp, scheduler: mockScheduler)

        stateObserver.btleListener(listener, didUpdateState: .poweredOn)

        XCTAssertEqual(0, mockScheduler.calls.count)
    }
}

class MockNotificationScheduler: LocalNotificationScheduling {
    typealias Call = (String, TimeInterval, String)

    var calls: [Call] = []

    func scheduleLocalNotification(body: String, interval: TimeInterval, identifier: String) {
        calls.append((body, interval, identifier))
    }
}

struct DummyApp : ApplicationStateReading {
    var applicationState: UIApplication.State

    init(_ state: UIApplication.State) {
        self.applicationState = state
    }
}
