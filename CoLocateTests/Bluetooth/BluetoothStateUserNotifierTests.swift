//
//  BluetoothStateUserNotifierTests.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
import UIKit
import CoreBluetooth

@testable import Sonar

class BluetoothStateUserNotifierTests: TestCase {

    private let foregroundApp = DummyApp(UIApplication.State.active)
    private let backgroundApp = DummyApp(UIApplication.State.background)

    func test_it_does_nothing_in_the_foreground() {
        let stateObserver = BluetoothStateObserver(initialState: .unknown)
        let mockScheduler = MockNotificationScheduler()
        let _ = BluetoothStateUserNotifier(appStateReader: foregroundApp, bluetoothStateObserver: stateObserver, scheduler: mockScheduler)

        stateObserver.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOff)

        XCTAssertEqual(0, mockScheduler.calls.count)
    }

    func test_it_creates_local_notifications_in_the_backgrouund_when_bluetooth_is_powered_off() {
        let stateObserver = BluetoothStateObserver(initialState: .unknown)
        let mockScheduler = MockNotificationScheduler()
        let _ = BluetoothStateUserNotifier(appStateReader: backgroundApp, bluetoothStateObserver: stateObserver, scheduler: mockScheduler, uiQueue: QueueDouble())

        stateObserver.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOff)

        XCTAssertEqual(1, mockScheduler.calls.count)
        guard mockScheduler.calls.count == 1 else {
            XCTFail("Expected one call but got \(mockScheduler.calls.count)")
            return
        }

        XCTAssertEqual(mockScheduler.calls[0].0, "Please turn Bluetooth on")
        XCTAssertEqual(mockScheduler.calls[0].1, "This app can only protect you and others if Bluetooth is on all the time.")
        XCTAssertEqual(mockScheduler.calls[0].2, 3)
        XCTAssertEqual(mockScheduler.calls[0].3, "bluetooth.disabled.please")
        XCTAssertEqual(mockScheduler.calls[0].4, false)
    }

    func test_it_does_nothing_when_bluetooth_is_powered_on() {
        let stateObserver = BluetoothStateObserver(initialState: .unknown)
        let mockScheduler = MockNotificationScheduler()
        _ = BluetoothStateUserNotifier(appStateReader: backgroundApp, bluetoothStateObserver: stateObserver, scheduler: mockScheduler)

        stateObserver.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOn)

        XCTAssertEqual(0, mockScheduler.calls.count)
    }
}

fileprivate class MockNotificationScheduler: LocalNotificationScheduling {
    typealias Call = (String?, String, TimeInterval, String, Bool)

    var calls: [Call] = []

    func scheduleLocalNotification(title: String?, body: String, interval: TimeInterval, identifier: String, repeats: Bool) {
        calls.append((title, body, interval, identifier, repeats))
    }
}

fileprivate struct DummyApp : ApplicationStateReading {
    var applicationState: UIApplication.State

    init(_ state: UIApplication.State) {
        self.applicationState = state
    }
}
