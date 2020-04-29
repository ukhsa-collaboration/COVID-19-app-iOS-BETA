//
//  OnboardingCoordinatorTests.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
import CoreBluetooth
@testable import Sonar

class OnboardingCoordinatorTests: TestCase {
    
    private var persistenceDouble: PersistenceDouble!
    private var authManagerDouble: AuthorizationManagerDouble!
    private var bluetoothNursery: BluetoothNurseryDouble!
    private var onboardingCoordinator: OnboardingCoordinator!
    
    override func setUp() {
        super.setUp()
        
        persistenceDouble = PersistenceDouble()
        authManagerDouble = AuthorizationManagerDouble()
        bluetoothNursery = BluetoothNurseryDouble()
        
        onboardingCoordinator = OnboardingCoordinator(
            persistence: persistenceDouble,
            authorizationManager: authManagerDouble,
            bluetoothNursery: bluetoothNursery
        )
    }

    func testInitialState() {
        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }
        XCTAssertEqual(state, .initial)
    }

    func testPostcode() {
        advancePastInitialScreen(onboardingCoordinator)

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }

        XCTAssertEqual(state, .partialPostcode)
    }

    func testPermissions_bluetoothNotDetermined() {
        persistenceDouble.partialPostcode = "1234"
        authManagerDouble.bluetooth = .notDetermined
        
        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }

        XCTAssertEqual(state, .permissions)
    }
    
    func testBluetoothDenied() {
        persistenceDouble.partialPostcode = "1234"
        authManagerDouble.bluetooth = .denied

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }
        
        XCTAssertEqual(state, .bluetoothDenied)
    }
        
    func testBluetoothOff() {
        persistenceDouble.partialPostcode = "1234"
        authManagerDouble.bluetooth = .allowed
        
        bluetoothNursery.startBluetooth(registration: nil)

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }
        XCTAssertNil(state)
        
        bluetoothNursery.stateObserver.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOff)
        XCTAssertEqual(state, .bluetoothOff)
    }

    func testPermissions_bluetoothGranted_notficationsNotDetermined() {
        persistenceDouble.partialPostcode = "1234"
        authManagerDouble.bluetooth = .allowed

        bluetoothNursery.startBluetooth(registration: nil)

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }
        bluetoothNursery.stateObserver.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOn)
        authManagerDouble.notificationsCompletion?(.notDetermined)
        
        XCTAssertEqual(state, .permissions)
    }
    
    func testDoesNotGetStuckOnBluetoothWhenAuthorizedButNotStarted() {
        persistenceDouble.partialPostcode = "1234"
        authManagerDouble.bluetooth = .allowed

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
        persistenceDouble.partialPostcode = "1234"
        authManagerDouble.bluetooth = .allowed

        bluetoothNursery.startBluetooth(registration: nil)

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }
        bluetoothNursery.stateObserver.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOn)
        authManagerDouble.notificationsCompletion?(.denied)
        XCTAssertEqual(state, .notificationsDenied)
    }

    func testDone() {
        persistenceDouble.partialPostcode = "1234"
        authManagerDouble.bluetooth = .allowed

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
