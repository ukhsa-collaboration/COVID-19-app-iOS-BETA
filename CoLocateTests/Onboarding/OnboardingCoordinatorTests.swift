//
//  OnboardingCoordinatorTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class OnboardingCoordinatorTests: TestCase {

    func testInitialState() {
        let persistenceDouble = PersistenceDouble()
        let authManagerDouble = AuthorizationManagerDouble()
        let onboardingCoordinator = OnboardingCoordinator(
            persistence: persistenceDouble,
            authorizationManager: authManagerDouble
        )

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }
        XCTAssertEqual(state, .initial)
    }

    func testPostcode() {
        let persistenceDouble = PersistenceDouble(partialPostcode: nil)
        let onboardingCoordinator = OnboardingCoordinator(
            persistence: persistenceDouble,
            authorizationManager: AuthorizationManagerDouble()
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
            authorizationManager: authManagerDouble
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
            authorizationManager: authManagerDouble
        )

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }
        
        XCTAssertEqual(state, .bluetoothDenied)
    }

    func testPermissions_bluetoothGranted_notficationsNotDetermined() {
        let persistenceDouble = PersistenceDouble(partialPostcode: "1234")
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .allowed)
        let onboardingCoordinator = OnboardingCoordinator(
            persistence: persistenceDouble,
            authorizationManager: authManagerDouble
        )

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }
        authManagerDouble.notificationsCompletion!(.notDetermined)
        
        XCTAssertEqual(state, .permissions)
    }
    
    func testNotificationsDenied() {
        let persistenceDouble = PersistenceDouble(partialPostcode: "1234")
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .allowed)
        let onboardingCoordinator = OnboardingCoordinator(
            persistence: persistenceDouble,
            authorizationManager: authManagerDouble
        )

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }
        authManagerDouble.notificationsCompletion!(.denied)
        XCTAssertEqual(state, .notificationsDenied)
    }

    func testDone() {
        let persistenceDouble = PersistenceDouble(partialPostcode: "1234")
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .allowed)
        let onboardingCoordinator = OnboardingCoordinator(
            persistence: persistenceDouble,
            authorizationManager: authManagerDouble
        )

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }
        authManagerDouble.notificationsCompletion!(.allowed)
        XCTAssertEqual(state, .done)
    }

    private func advancePastInitialScreen(_ onboardingCoordinator: OnboardingCoordinator) {
        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }

        XCTAssertEqual(state, .initial)
    }
}
