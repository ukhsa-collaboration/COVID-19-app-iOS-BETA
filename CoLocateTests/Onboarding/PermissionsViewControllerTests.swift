//
//  PermissionsViewControllerTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import CoreBluetooth
import XCTest
@testable import CoLocate

class PermissionsViewControllerTests: TestCase {

    func testPermissionsFlow() {
        let authManagerDouble = AuthorizationManagerDouble()
        let remoteNotificationManagerDouble = RemoteNotificationManagerDouble()
        let vc = PermissionsViewController.instantiate()
        var continued = false
        vc.inject(authManager: authManagerDouble, remoteNotificationManager: remoteNotificationManagerDouble, uiQueue: QueueDouble()) {
            continued = true
        }

        parentViewControllerForTests.viewControllers = [vc]

        vc.didTapContinue(UIButton())
        
        #if targetEnvironment(simulator)
        // We skip Bluetooth on the simulator and jump straight
        // to requesting notification authorization.
        #else
        authManagerDouble.bluetooth = .allowed
        vc.btleBroadcaster(DummyBTLEBroadcaster(), didUpdateState: .poweredOn)
        #endif

        XCTAssertNotNil(authManagerDouble.notificationsCompletion)
        authManagerDouble.notificationsCompletion!(.notDetermined)

        XCTAssertNotNil(remoteNotificationManagerDouble.requestAuthorizationCompletion)
        remoteNotificationManagerDouble.requestAuthorizationCompletion?(.success(true))

        XCTAssert(continued)
    }

    func testBluetoothAlreadyDetermined() {
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .allowed)
        let remoteNotificationManagerDouble = RemoteNotificationManagerDouble()
        let vc = PermissionsViewController.instantiate()
        var continued = false
        vc.inject(authManager: authManagerDouble, remoteNotificationManager: remoteNotificationManagerDouble, uiQueue: QueueDouble()) {
            continued = true
        }

        parentViewControllerForTests.viewControllers = [vc]

        vc.didTapContinue(UIButton())

        XCTAssertNotNil(authManagerDouble.notificationsCompletion)
        authManagerDouble.notificationsCompletion!(.notDetermined)

        XCTAssertNotNil(remoteNotificationManagerDouble.requestAuthorizationCompletion)
        remoteNotificationManagerDouble.requestAuthorizationCompletion?(.success(true))

        XCTAssert(continued)
    }

    func testNotificationsAlreadyDetermined() {
        let authManagerDouble = AuthorizationManagerDouble()
        let remoteNotificationManagerDouble = RemoteNotificationManagerDouble()
        let vc = PermissionsViewController.instantiate()
        var continued = false
        vc.inject(authManager: authManagerDouble, remoteNotificationManager: remoteNotificationManagerDouble, uiQueue: QueueDouble()) {
            continued = true
        }

        parentViewControllerForTests.viewControllers = [vc]

        vc.didTapContinue(UIButton())

        #if targetEnvironment(simulator)
        // We skip Bluetooth on the simulator and jump straight
        // to requesting notification authorization.
        #else
        authManagerDouble.bluetooth = .allowed
        vc.btleBroadcaster(DummyBTLEBroadcaster(), didUpdateState: .poweredOn)
        #endif

        XCTAssertNotNil(authManagerDouble.notificationsCompletion)
        authManagerDouble.notificationsCompletion!(.allowed)

        XCTAssert(continued)
    }

}

fileprivate struct DummyBTLEBroadcaster: BTLEBroadcaster {
    var sonarId: UUID?
}
