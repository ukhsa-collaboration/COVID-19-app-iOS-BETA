//
//  SetupCheckerTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class SetupCheckerTests: XCTestCase {
    func testAllOk_withBluetoothObserver_btFinishesFirst() {
        let authMgr = AuthorizationManagerDouble(bluetooth: .allowed)
        let nursery = BluetoothNurseryDouble()
        let checker = SetupChecker(authorizationManager: authMgr, bluetoothNursery: nursery)
        nursery.startBluetooth(registration: nil)
        nursery.stateObserver?.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOn)

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
     
    func testAllOk_withBluetoothObserver_notificationsFinishesFirst() {
        let authMgr = AuthorizationManagerDouble(bluetooth: .allowed)
        let nursery = BluetoothNurseryDouble()
        let checker = SetupChecker(authorizationManager: authMgr, bluetoothNursery: nursery)
        nursery.startBluetooth(registration: nil)

        var result: SetupProblem? = nil
        var called = false
        checker.check({ problem in
            result = problem
            called = true
        })
        authMgr.notificationsCompletion?(.allowed)
        nursery.stateObserver?.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOn)

        XCTAssertNil(result)
        XCTAssertTrue(called)
    }
     
    func testAllOk_withoutBluetoothObserver() {
        let authMgr = AuthorizationManagerDouble(bluetooth: .allowed)
        let nursery = BluetoothNurseryDouble()
        let checker = SetupChecker(authorizationManager: authMgr, bluetoothNursery: nursery)
        XCTAssertNil(nursery.stateObserver)
        
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
     
    func testBluetoothOffTrumpsEverything() {
        let authMgr = AuthorizationManagerDouble(bluetooth: .denied)
        let nursery = BluetoothNurseryDouble()
        let checker = SetupChecker(authorizationManager: authMgr, bluetoothNursery: nursery)
        nursery.startBluetooth(registration: nil)
        
        var result: SetupProblem? = nil
        checker.check({ problem in result = problem })
        authMgr.notificationsCompletion?(.denied)
        nursery.stateObserver?.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOff)
        
        XCTAssertEqual(result, .bluetoothOff)
    }
    
    func testBluetoothPermissions_withBluetoothObserver() {
        let authMgr = AuthorizationManagerDouble(bluetooth: .denied)
        let nursery = BluetoothNurseryDouble()
        let checker = SetupChecker(authorizationManager: authMgr, bluetoothNursery: nursery)
        nursery.startBluetooth(registration: nil)
        nursery.stateObserver?.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOn)

        var result: SetupProblem? = nil
        checker.check({ problem in result = problem })
        authMgr.notificationsCompletion?(.denied)
        
        XCTAssertEqual(result, .bluetoothPermissions)
    }
    
    func testBluetoothPermissions_withoutBluetoothObserver() {
        let authMgr = AuthorizationManagerDouble(bluetooth: .denied)
        let nursery = BluetoothNurseryDouble()
        let checker = SetupChecker(authorizationManager: authMgr, bluetoothNursery: nursery)
        XCTAssertNil(nursery.stateObserver)

        var result: SetupProblem? = nil
        checker.check({ problem in result = problem })
        authMgr.notificationsCompletion?(.denied)
        
        XCTAssertEqual(result, .bluetoothPermissions)
    }
    
    func testNotificationPermissions_withBluetoothObserver() {
        let authMgr = AuthorizationManagerDouble(bluetooth: .allowed)
        let nursery = BluetoothNurseryDouble()
        let checker = SetupChecker(authorizationManager: authMgr, bluetoothNursery: nursery)
        nursery.startBluetooth(registration: nil)
        nursery.stateObserver?.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOn)

        var result: SetupProblem? = nil
        checker.check({ problem in result = problem })
        authMgr.notificationsCompletion?(.denied)
        
        XCTAssertEqual(result, .notificationPermissions)
    }
    
    func testNotificationPermissions_withoutBluetoothObserver() {
        let authMgr = AuthorizationManagerDouble(bluetooth: .allowed)
        let nursery = BluetoothNurseryDouble()
        let checker = SetupChecker(authorizationManager: authMgr, bluetoothNursery: nursery)
        XCTAssertNil(nursery.stateObserver)

        var result: SetupProblem? = nil
        checker.check({ problem in result = problem })
        authMgr.notificationsCompletion?(.denied)
        
        XCTAssertEqual(result, .notificationPermissions)
    }
}
