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
        let persistenceDouble = PersistenceDouble(allowedDataSharing: false)
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .notDetermined)
        let onboardingCoordinator = OnboardingCoordinator(
            persistence: persistenceDouble,
            authorizationManager: authManagerDouble
        )

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }
        XCTAssertEqual(state, .initial)
    }
    
    func testPostcode() {
        let persistenceDouble = PersistenceDouble(allowedDataSharing: true, partialPostcode: nil)
        let onboardingCoordinator = OnboardingCoordinator(
            persistence: persistenceDouble,
            authorizationManager: AuthorizationManagerDouble()
        )

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }

        XCTAssertEqual(state, .partialPostcode)

    }

    func testPermissions() {
        let persistenceDouble = PersistenceDouble(allowedDataSharing: true, partialPostcode: "1234")
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .notDetermined)
        let onboardingCoordinator = OnboardingCoordinator(
            persistence: persistenceDouble,
            authorizationManager: authManagerDouble
        )

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }
        authManagerDouble.notificationsCompletion!(.notDetermined)

        XCTAssertEqual(state, .permissions)
    }

    func testNotificationPermissions() {
        let persistenceDouble = PersistenceDouble(allowedDataSharing: true, partialPostcode: "1234")
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
    
    func testPermissionsDenied() {
        let persistenceDouble = PersistenceDouble(allowedDataSharing: true, partialPostcode: "1234")
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .allowed)
        let onboardingCoordinator = OnboardingCoordinator(
            persistence: persistenceDouble,
            authorizationManager: authManagerDouble
        )

        var state: OnboardingCoordinator.State?
        onboardingCoordinator.state { state = $0 }
        authManagerDouble.notificationsCompletion!(.denied)
        XCTAssertEqual(state, .permissionsDenied)
    }

    func testDone() {
        let persistenceDouble = PersistenceDouble(allowedDataSharing: true, partialPostcode: "1234")
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
}
