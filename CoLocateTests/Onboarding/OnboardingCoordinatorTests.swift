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
            bluetoothStateObserver: BluetoothStateObserverDouble()
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
            bluetoothStateObserver: BluetoothStateObserverDouble()
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
            bluetoothStateObserver: BluetoothStateObserverDouble()
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
            bluetoothStateObserver: BluetoothStateObserverDouble()
        )

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }
        
        XCTAssertEqual(state, .bluetoothDenied)
    }
    
    func testBluetoothOff_initially() {
        let persistenceDouble = PersistenceDouble(allowedDataSharing: true, partialPostcode: "1234")
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .allowed)
        let bluetoothStateObserver = BluetoothStateObserverDouble(initialState: .poweredOff)
        let onboardingCoordinator = OnboardingCoordinator(
            persistence: persistenceDouble,
            authorizationManager: authManagerDouble,
            bluetoothStateObserver: bluetoothStateObserver
        )

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }
        
        XCTAssertEqual(state, .bluetoothOff)
    }
    
    func testBluetoothOff_afterDelay() {
        let persistenceDouble = PersistenceDouble(allowedDataSharing: true, partialPostcode: "1234")
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .allowed)
        let bluetoothStateObserver = BluetoothStateObserverDouble(initialState: .unknown)
        let onboardingCoordinator = OnboardingCoordinator(
            persistence: persistenceDouble,
            authorizationManager: authManagerDouble,
            bluetoothStateObserver: bluetoothStateObserver
        )

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }
        
        XCTAssertNil(state)
        
        bluetoothStateObserver.delegate?.bluetoothStateObserver(bluetoothStateObserver, didChangeState: .poweredOff)
        
        XCTAssertEqual(state, .bluetoothOff)
    }

    func testPermissions_bluetoothGranted_notficationsNotDetermined() {
        let persistenceDouble = PersistenceDouble(partialPostcode: "1234")
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .allowed)
        let onboardingCoordinator = OnboardingCoordinator(
            persistence: persistenceDouble,
            authorizationManager: authManagerDouble,
            bluetoothStateObserver: BluetoothStateObserverDouble(initialState: .poweredOn)
        )

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }
        authManagerDouble.notificationsCompletion?(.notDetermined)
        
        XCTAssertEqual(state, .permissions)
    }
    
    func testNotificationsDenied() {
        let persistenceDouble = PersistenceDouble(partialPostcode: "1234")
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .allowed)
        let onboardingCoordinator = OnboardingCoordinator(
            persistence: persistenceDouble,
            authorizationManager: authManagerDouble,
            bluetoothStateObserver: BluetoothStateObserverDouble(initialState: .poweredOn)
        )

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }
        authManagerDouble.notificationsCompletion?(.denied)
        XCTAssertEqual(state, .notificationsDenied)
    }

    func testDone() {
        let persistenceDouble = PersistenceDouble(partialPostcode: "1234")
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .allowed)
        let onboardingCoordinator = OnboardingCoordinator(
            persistence: persistenceDouble,
            authorizationManager: authManagerDouble,
            bluetoothStateObserver: BluetoothStateObserverDouble(initialState: .poweredOn)
        )

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }
        authManagerDouble.notificationsCompletion?(.allowed)
        XCTAssertEqual(state, .done)
    }

    private func advancePastInitialScreen(_ onboardingCoordinator: OnboardingCoordinator) {
        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }

        XCTAssertEqual(state, .initial)
    }
}
