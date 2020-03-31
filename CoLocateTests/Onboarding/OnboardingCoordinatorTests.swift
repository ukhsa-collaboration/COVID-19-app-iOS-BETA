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
        let persistanceDouble = PersistanceDouble(allowedDataSharing: false)
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .notDetermined)
        let onboardingCoordinator = OnboardingCoordinator(
            persistance: persistanceDouble,
            authorizationManager: authManagerDouble
        )

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }
        XCTAssertEqual(state, .initial)
    }

    func testBluetoothPermissions() {
        let persistanceDouble = PersistanceDouble(allowedDataSharing: true)
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .notDetermined)
        let onboardingCoordinator = OnboardingCoordinator(
            persistance: persistanceDouble,
            authorizationManager: authManagerDouble
        )

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }
        XCTAssertEqual(state, .permissions)
    }

    func testNotificationPermissions() {
        let persistanceDouble = PersistanceDouble(allowedDataSharing: true)
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .allowed)
        let onboardingCoordinator = OnboardingCoordinator(
            persistance: persistanceDouble,
            authorizationManager: authManagerDouble
        )

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }
        authManagerDouble.notificationsCompletion!(.notDetermined)
        XCTAssertEqual(state, .permissions)
    }

    func testRegistration() {
        let persistanceDouble = PersistanceDouble(allowedDataSharing: true)
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .allowed)
        let onboardingCoordinator = OnboardingCoordinator(
            persistance: persistanceDouble,
            authorizationManager: authManagerDouble
        )

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }
        authManagerDouble.notificationsCompletion!(.allowed)
        XCTAssertEqual(state, .registration)
    }

    func testDoneOnboarding() {
        let registration = Registration(id: UUID(), secretKey: Data())
        let persistanceDouble = PersistanceDouble(allowedDataSharing: true, registration: registration)
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .allowed)
        let onboardingCoordinator = OnboardingCoordinator(
            persistance: persistanceDouble,
            authorizationManager: authManagerDouble
        )

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }
        authManagerDouble.notificationsCompletion!(.allowed)
        XCTAssertEqual(state, nil)
    }

}
