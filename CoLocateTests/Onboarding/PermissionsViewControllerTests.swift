//
//  PermissionsViewControllerTests.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import CoreBluetooth
import XCTest
@testable import Sonar

class PermissionsViewControllerTests: TestCase {
    
    func test_ios13_BluetoothNotDetermined_callsContinueHandlerWhenBothGranted() {
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .notDetermined)
        let remoteNotificationManagerDouble = RemoteNotificationManagerDouble()
        let nursery = BluetoothNurseryDouble()
        let persistence = PersistenceDouble()
        let vc = PermissionsViewController.instantiate()
        var continued = false
        vc.inject(authManager: authManagerDouble,
                  remoteNotificationManager: remoteNotificationManagerDouble,
                  bluetoothNursery: nursery,
                  persistence: persistence,
                  uiQueue: QueueDouble()) {
            continued = true
        }

        parentViewControllerForTests.viewControllers = [vc]
        XCTAssertNotNil(vc.view)

        vc.didTapContinue()

        XCTAssertTrue(persistence.bluetoothPermissionRequested)

        #if targetEnvironment(simulator)
        // We skip Bluetooth on the simulator.
        #else
        authManagerDouble.bluetooth = .allowed
        nursery.stateObserver.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOn)
        #endif
        
        XCTAssertFalse(continued)
        XCTAssertNotNil(authManagerDouble.notificationsCompletion)
        authManagerDouble.notificationsCompletion?(.allowed)
        XCTAssertTrue(continued)
    }

    func test_ios12_BluetoothNotDetermined_callsContinueHandlerWhenViewAppearsAfterBothGranted() {
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .notDetermined)
        let remoteNotificationManagerDouble = RemoteNotificationManagerDouble()
        let nursery = BluetoothNurseryDouble()
        let persistence = PersistenceDouble()
        let vc = PermissionsViewController.instantiate()
        var continued = false
        vc.inject(authManager: authManagerDouble,
                  remoteNotificationManager: remoteNotificationManagerDouble,
                  bluetoothNursery: nursery,
                  persistence: persistence,
                  uiQueue: QueueDouble()) {
            continued = true
        }

        parentViewControllerForTests.viewControllers = [vc]
        XCTAssertNotNil(vc.view)

        vc.didTapContinue()

        XCTAssertTrue(persistence.bluetoothPermissionRequested)

        #if targetEnvironment(simulator)
        // We skip Bluetooth on the simulator.
        #else
        nursery.stateObserver.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOn)
        authManagerDouble.bluetooth = .allowed
        vc.viewWillAppear(false) // called when the user returns to the app
        XCTAssertNotNil(authManagerDouble.bluetoothCompletion)
        authManagerDouble.bluetoothCompletion?(.allowed)
        #endif

        XCTAssertFalse(continued)
        XCTAssertNotNil(authManagerDouble.notificationsCompletion)
        authManagerDouble.notificationsCompletion?(.allowed)
        XCTAssertTrue(continued)
    }

    func test_ios12_BluetoothNotDetermined_requestsNotificationAuthWhenBluetoothDenied() {
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .notDetermined)
        let remoteNotificationManagerDouble = RemoteNotificationManagerDouble()
        let nursery = BluetoothNurseryDouble()
        let persistence = PersistenceDouble()
        let vc = PermissionsViewController.instantiate()
        var continued = false
        vc.inject(authManager: authManagerDouble,
                  remoteNotificationManager: remoteNotificationManagerDouble,
                  bluetoothNursery: nursery,
                  persistence: persistence,
                  uiQueue: QueueDouble()) {
            continued = true
        }

        parentViewControllerForTests.viewControllers = [vc]
        XCTAssertNotNil(vc.view)

        vc.didTapContinue()

        XCTAssertTrue(persistence.bluetoothPermissionRequested)

        #if targetEnvironment(simulator)
        // We skip Bluetooth on the simulator.
        #else
        nursery.stateObserver.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOn)
        authManagerDouble.bluetooth = .allowed
        vc.viewWillAppear(false) // called when the user returns to the app
        XCTAssertNotNil(authManagerDouble.bluetoothCompletion)
        authManagerDouble.bluetoothCompletion?(.denied)
        #endif

        XCTAssertFalse(continued)
        XCTAssertNotNil(authManagerDouble.notificationsCompletion)
    }

    func testBluetoothNotDetermined_callsContinueHandlerOnChangeToDenied() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("This test can't run in the simulator.")
        #else
        
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .notDetermined)
        let remoteNotificationManagerDouble = RemoteNotificationManagerDouble()
        let nursery = BluetoothNurseryDouble()
        let persistence = PersistenceDouble()
        let vc = PermissionsViewController.instantiate()
        var continued = false
        vc.inject(authManager: authManagerDouble,
                  remoteNotificationManager: remoteNotificationManagerDouble,
                  bluetoothNursery: nursery,
                  persistence: persistence,
                  uiQueue: QueueDouble()) {
            continued = true
        }

        parentViewControllerForTests.viewControllers = [vc]
        XCTAssertNotNil(vc.view)

        vc.didTapContinue()

        XCTAssertTrue(persistence.bluetoothPermissionRequested)
        
        authManagerDouble.bluetooth = .denied
        nursery.stateObserver.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOn)

        XCTAssert(continued)
        
        #endif
    }
    
    func testBluetoothAllowed_promptsForNotificationWhenShown() {
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .allowed)
        let remoteNotificationManagerDouble = RemoteNotificationManagerDouble()
        let vc = PermissionsViewController.instantiate()
        var continued = false
        vc.inject(authManager: authManagerDouble,
                  remoteNotificationManager: remoteNotificationManagerDouble,
                  bluetoothNursery: BluetoothNurseryDouble(),
                  persistence: PersistenceDouble(),
                  uiQueue: QueueDouble()) {
            continued = true
        }

        parentViewControllerForTests.viewControllers = [vc]
        XCTAssertNotNil(vc.view)
        vc.viewWillAppear(false)

        XCTAssertFalse(continued)
        XCTAssertNotNil(authManagerDouble.bluetoothCompletion)
        authManagerDouble.bluetoothCompletion?(.allowed)
        XCTAssertNotNil(authManagerDouble.notificationsCompletion)
        authManagerDouble.notificationsCompletion?(.allowed)
        XCTAssertTrue(continued)
    }

    func testPreventsDoubleSubmit() {
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .allowed)
        let remoteNotificationManagerDouble = RemoteNotificationManagerDouble()
        let vc = PermissionsViewController.instantiate()
        vc.inject(authManager: authManagerDouble,
                  remoteNotificationManager: remoteNotificationManagerDouble,
                  bluetoothNursery: BluetoothNurseryDouble(),
                  persistence: PersistenceDouble(),
                  uiQueue: QueueDouble()) {}

        parentViewControllerForTests.viewControllers = [vc]
        XCTAssertNotNil(vc.view)
        vc.viewWillAppear(false)
        XCTAssertTrue(vc.activityIndicator.isHidden)
        XCTAssertFalse(vc.continueButton.isHidden)

        vc.didTapContinue()
        
        XCTAssertFalse(vc.activityIndicator.isHidden)
        XCTAssertTrue(vc.activityIndicator.isAnimating)
        XCTAssertTrue(vc.continueButton.isHidden)
    }
    
    func testBluetoothAlreadyDetermined() {
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .allowed)
        let remoteNotificationManagerDouble = RemoteNotificationManagerDouble()
        let vc = PermissionsViewController.instantiate()
        var continued = false
        vc.inject(authManager: authManagerDouble,
                  remoteNotificationManager: remoteNotificationManagerDouble,
                  bluetoothNursery: BluetoothNurseryDouble(),
                  persistence: PersistenceDouble(),
                  uiQueue: QueueDouble()) {
            continued = true
        }

        parentViewControllerForTests.viewControllers = [vc]
        XCTAssertNotNil(vc.view)

        vc.didTapContinue()

        XCTAssertNotNil(authManagerDouble.notificationsCompletion)
        authManagerDouble.notificationsCompletion!(.notDetermined)

        XCTAssertNotNil(remoteNotificationManagerDouble.requestAuthorizationCompletion)
        remoteNotificationManagerDouble.requestAuthorizationCompletion?(.success(true))

        XCTAssert(continued)
    }

}

fileprivate struct DummyBTLEListener: BTLEListener {
    func start(stateDelegate: BTLEListenerStateDelegate?, delegate: BTLEListenerDelegate?) { }
    func connect(_ peripheral: BTLEPeripheral) { }
    func isHealthy() -> Bool { return false }
}
