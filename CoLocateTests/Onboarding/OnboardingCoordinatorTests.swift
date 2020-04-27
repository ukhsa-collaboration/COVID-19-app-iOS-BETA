//
//  OnboardingCoordinatorTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
import CoreBluetooth
@testable import CoLocate

class OnboardingCoordinatorTests: TestCase {

    func testInitialState() {
        let persistenceDouble = PersistenceDouble()
        let authManagerDouble = AuthorizationManagerDouble()
        let onboardingCoordinator = OnboardingCoordinator(
            persistence: persistenceDouble,
            authorizationManager: authManagerDouble,
            bluetoothNursery: BluetoothNurseryDouble()
        )

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }
        XCTAssertEqual(state, .initial)
    }

    func testPostcode() {
        let persistenceDouble = PersistenceDouble(partialPostcode: nil)
        let onboardingCoordinator = OnboardingCoordinator(
            persistence: persistenceDouble,
            authorizationManager: AuthorizationManagerDouble(),
            bluetoothNursery: BluetoothNurseryDouble()
        )

        advancePastInitialScreen(onboardingCoordinator)

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }

        XCTAssertEqual(state, .partialPostcode)

    }

    func testPermissions_bluetoothNotDetermined() {
        let persistenceDouble = PersistenceDouble(partialPostcode: "1234")
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .notDetermined)
        let onboardingCoordinator = OnboardingCoordinator(
            persistence: persistenceDouble,
            authorizationManager: authManagerDouble,
            bluetoothNursery: BluetoothNurseryDouble()
        )

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }

        XCTAssertEqual(state, .permissions)
    }
    
    func testBluetoothDenied() {
        let persistenceDouble = PersistenceDouble(partialPostcode: "1234")
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .denied)
        let onboardingCoordinator = OnboardingCoordinator(
            persistence: persistenceDouble,
            authorizationManager: authManagerDouble,
            bluetoothNursery: BluetoothNurseryDouble()
        )

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }
        
        XCTAssertEqual(state, .bluetoothDenied)
    }
        
    func testBluetoothOff() {
        let persistenceDouble = PersistenceDouble(partialPostcode: "1234")
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .allowed)
        let bluetoothNursery = BluetoothNurseryDouble()
        let onboardingCoordinator = OnboardingCoordinator(
            persistence: persistenceDouble,
            authorizationManager: authManagerDouble,
            bluetoothNursery: bluetoothNursery
        )
        
        bluetoothNursery.startBluetooth(registration: nil)

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }
        XCTAssertNil(state)
        
        bluetoothNursery.stateObserver.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOff)
        XCTAssertEqual(state, .bluetoothOff)
    }

    func testPermissions_bluetoothGranted_notficationsNotDetermined() {
        let persistenceDouble = PersistenceDouble(partialPostcode: "1234")
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .allowed)
        let bluetoothNursery = BluetoothNurseryDouble()
        let onboardingCoordinator = OnboardingCoordinator(
            persistence: persistenceDouble,
            authorizationManager: authManagerDouble,
            bluetoothNursery: bluetoothNursery
        )

        bluetoothNursery.startBluetooth(registration: nil)

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }
        bluetoothNursery.stateObserver.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOn)
        authManagerDouble.notificationsCompletion?(.notDetermined)
        
        XCTAssertEqual(state, .permissions)
    }
    
    func testDoesNotGetStuckOnBluetoothWhenAuthorizedButNotStarted() {
        let persistenceDouble = PersistenceDouble(partialPostcode: "1234")
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .allowed)
        let bluetoothNursery = BluetoothNurseryDouble()
        let onboardingCoordinator = OnboardingCoordinator(
            persistence: persistenceDouble,
            authorizationManager: authManagerDouble,
            bluetoothNursery: bluetoothNursery
        )

        XCTAssertFalse(bluetoothNursery.hasStarted)

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }
        
        XCTAssertTrue(bluetoothNursery.hasStarted)
        bluetoothNursery.stateObserver.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOn)
        XCTAssertNotNil(authManagerDouble.notificationsCompletion)
        authManagerDouble.notificationsCompletion?(.allowed)
        XCTAssertEqual(state, .done)
    }
    
    func testNotificationsDenied() {
        let persistenceDouble = PersistenceDouble(partialPostcode: "1234")
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .allowed)
        let bluetoothNursery = BluetoothNurseryDouble()
        let onboardingCoordinator = OnboardingCoordinator(
            persistence: persistenceDouble,
            authorizationManager: authManagerDouble,
            bluetoothNursery: bluetoothNursery
        )
        
        bluetoothNursery.startBluetooth(registration: nil)

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }
        bluetoothNursery.stateObserver.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOn)
        authManagerDouble.notificationsCompletion?(.denied)
        XCTAssertEqual(state, .notificationsDenied)
    }

    func testDone() {
        let persistenceDouble = PersistenceDouble(partialPostcode: "1234")
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .allowed)
        let bluetoothNursery = BluetoothNurseryDouble()
        let onboardingCoordinator = OnboardingCoordinator(
            persistence: persistenceDouble,
            authorizationManager: authManagerDouble,
            bluetoothNursery: bluetoothNursery
        )

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }
        bluetoothNursery.stateObserver.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOn)
        authManagerDouble.notificationsCompletion?(.allowed)
        XCTAssertEqual(state, .done)
    }

    private func advancePastInitialScreen(_ onboardingCoordinator: OnboardingCoordinator) {
        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }

        XCTAssertEqual(state, .initial)
    }
}
