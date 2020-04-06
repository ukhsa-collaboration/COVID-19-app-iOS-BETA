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
        let persistence = PersistenceDouble()
        let vc = PermissionsViewController.instantiate()
        vc.authManager = authManagerDouble
        vc.remoteNotificationManager = remoteNotificationManagerDouble
        vc.persistence = persistence
        vc.uiQueue = QueueDouble()

        let permissionsUnwinder = PermissionsUnwinder()
        rootViewController.viewControllers = [permissionsUnwinder]
        permissionsUnwinder.present(vc, animated: false)

        vc.didTapContinue(UIButton())
        
        #if targetEnvironment(simulator)
        // We skip Bluetooth on the simulator and jump straight
        // to requesting notification authorization.
        #else
        authManagerDouble._bluetooth = .allowed
        vc.btleListener(DummyBTLEListener(), didUpdateState: .poweredOn)
        #endif

        XCTAssertNotNil(authManagerDouble.notificationsCompletion)
        authManagerDouble.notificationsCompletion!(.notDetermined)

        XCTAssertNotNil(remoteNotificationManagerDouble.requestAuthorizationCompletion)
        remoteNotificationManagerDouble.requestAuthorizationCompletion?(.success(true))

        XCTAssert(permissionsUnwinder.didUnwindFromPermissions)
    }

    func testBluetoothAlreadyDetermined() {
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .allowed)
        let remoteNotificationManagerDouble = RemoteNotificationManagerDouble()
        let persistence = PersistenceDouble()
        let vc = PermissionsViewController.instantiate()
        vc.authManager = authManagerDouble
        vc.remoteNotificationManager = remoteNotificationManagerDouble
        vc.persistence = persistence
        vc.uiQueue = QueueDouble()

        let permissionsUnwinder = PermissionsUnwinder()
        rootViewController.viewControllers = [permissionsUnwinder]
        permissionsUnwinder.present(vc, animated: false)

        vc.didTapContinue(UIButton())

        XCTAssertNotNil(authManagerDouble.notificationsCompletion)
        authManagerDouble.notificationsCompletion!(.notDetermined)

        XCTAssertNotNil(remoteNotificationManagerDouble.requestAuthorizationCompletion)
        remoteNotificationManagerDouble.requestAuthorizationCompletion?(.success(true))

        XCTAssert(permissionsUnwinder.didUnwindFromPermissions)
    }

    func testNotificationsAlreadyDetermined() {
        let authManagerDouble = AuthorizationManagerDouble()
        let remoteNotificationManagerDouble = RemoteNotificationManagerDouble()
        let persistence = PersistenceDouble()
        let vc = PermissionsViewController.instantiate()
        vc.authManager = authManagerDouble
        vc.remoteNotificationManager = remoteNotificationManagerDouble
        vc.persistence = persistence
        vc.uiQueue = QueueDouble()

        let permissionsUnwinder = PermissionsUnwinder()
        rootViewController.viewControllers = [permissionsUnwinder]
        permissionsUnwinder.present(vc, animated: false)

        vc.didTapContinue(UIButton())

        #if targetEnvironment(simulator)
        // We skip Bluetooth on the simulator and jump straight
        // to requesting notification authorization.
        #else
        authManagerDouble._bluetooth = .allowed
        vc.btleListener(DummyBTLEListener(), didUpdateState: .poweredOn)
        #endif

        XCTAssertNotNil(authManagerDouble.notificationsCompletion)
        authManagerDouble.notificationsCompletion!(.allowed)

        XCTAssert(permissionsUnwinder.didUnwindFromPermissions)
    }

}

class PermissionsUnwinder: UIViewController {
    var didUnwindFromPermissions = false
    @IBAction func unwindFromPermissions(unwindSegue: UIStoryboardSegue) {
        didUnwindFromPermissions = true
    }
}
