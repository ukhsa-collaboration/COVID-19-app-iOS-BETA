//
//  SetupCheckerTests.swift
//  SonarTests
//
//  Created by NHSX on 4/23/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class SetupCheckerTests: XCTestCase {
    func testAllOk_withBluetoothObserver_btFinishesFirst() {
        let authMgr = AuthorizationManagerDouble(bluetooth: .allowed)
        let nursery = BluetoothNurseryDouble()
        let checker = SetupChecker(authorizationManager: authMgr, bluetoothNursery: nursery)
        nursery.startBluetooth(registration: nil)
        nursery.stateObserver.listener(ListenerDouble(), didUpdateState: .poweredOn)

        var result: SetupProblem? = nil
        var called = false
        checker.check({ problem in
            result = problem
            called = true
        })
        authMgr.notificationsCompletion?(.allowed)
        
        XCTAssertNil(result)
        XCTAssertTrue(called)
    }
     
    func testAllOk_notificationsFinishesFirst() {
        let authMgr = AuthorizationManagerDouble(bluetooth: .allowed)
        let nursery = BluetoothNurseryDouble()
        let checker = SetupChecker(authorizationManager: authMgr, bluetoothNursery: nursery)

        var result: SetupProblem? = nil
        var called = false
        checker.check({ problem in
            result = problem
            called = true
        })
        authMgr.notificationsCompletion?(.allowed)
        nursery.stateObserver.listener(ListenerDouble(), didUpdateState: .poweredOn)

        XCTAssertNil(result)
        XCTAssertTrue(called)
    }

    func testBluetoothOffTrumpsEverything() {
        let authMgr = AuthorizationManagerDouble(bluetooth: .denied)
        let nursery = BluetoothNurseryDouble()
        let checker = SetupChecker(authorizationManager: authMgr, bluetoothNursery: nursery)
        nursery.startBluetooth(registration: nil)
        
        var result: SetupProblem? = nil
        checker.check({ problem in result = problem })
        authMgr.notificationsCompletion?(.denied)
        nursery.stateObserver.listener(ListenerDouble(), didUpdateState: .poweredOff)
        
        XCTAssertEqual(result, .bluetoothOff)
    }
    
    func testBluetoothPermissions_withBluetoothObserver() {
        let authMgr = AuthorizationManagerDouble(bluetooth: .denied)
        let nursery = BluetoothNurseryDouble()
        let checker = SetupChecker(authorizationManager: authMgr, bluetoothNursery: nursery)

        nursery.stateObserver.listener(ListenerDouble(), didUpdateState: .poweredOn)

        var result: SetupProblem? = nil
        checker.check({ problem in result = problem })
        authMgr.notificationsCompletion?(.denied)
        
        XCTAssertEqual(result, .bluetoothPermissions)
    }

    func testNotificationPermissions() {
        let authMgr = AuthorizationManagerDouble(bluetooth: .allowed)
        let nursery = BluetoothNurseryDouble()
        let checker = SetupChecker(authorizationManager: authMgr, bluetoothNursery: nursery)
        nursery.stateObserver.listener(ListenerDouble(), didUpdateState: .poweredOn)

        var result: SetupProblem? = nil
        checker.check({ problem in result = problem })
        authMgr.notificationsCompletion?(.denied)
        
        XCTAssertEqual(result, .notificationPermissions)
    }
}
