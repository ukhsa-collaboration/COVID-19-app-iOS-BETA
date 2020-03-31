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
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .notDetermined, notifications: .notDetermined)
        let onboardingCoordinator = OnboardingCoordinator(
            persistance: persistanceDouble,
            authorizationManager: authManagerDouble
        )

        XCTAssertEqual(onboardingCoordinator.state, .initial)
    }

    func testPermissions() {
        let persistanceDouble = PersistanceDouble(allowedDataSharing: true)
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .notDetermined, notifications: .notDetermined)
        let onboardingCoordinator = OnboardingCoordinator(
            persistance: persistanceDouble,
            authorizationManager: authManagerDouble
        )

        XCTAssertEqual(onboardingCoordinator.state, .permissions)
    }

    func testRegistration() {
        let persistanceDouble = PersistanceDouble(allowedDataSharing: true)
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .notDetermined, notifications: .notDetermined)
        let onboardingCoordinator = OnboardingCoordinator(
            persistance: persistanceDouble,
            authorizationManager: authManagerDouble
        )

        XCTAssertEqual(onboardingCoordinator.state, .permissions)
    }

    func testDoneOnboarding() {
        let registration = Registration(id: UUID(), secretKey: Data())
        let persistanceDouble = PersistanceDouble(allowedDataSharing: true, registration: registration)
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .allowed, notifications: .allowed)
        let onboardingCoordinator = OnboardingCoordinator(
            persistance: persistanceDouble,
            authorizationManager: authManagerDouble
        )

        XCTAssertEqual(onboardingCoordinator.state, nil)
    }

}
