//
//  OnboardingViewControllerTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class OnboardingViewControllerTests: TestCase {

    func testPresentsInitialState() {
        let coordinatorDouble = OnboardingCoordinatorDouble()
        let vc = OnboardingViewController.instantiate()
        vc.inject(env: envDouble(), coordinator: coordinatorDouble, uiQueue: QueueDouble()) {}
        let container = ViewControllerContainerDouble()
        vc.showIn(container: container)

        vc.updateState()
        coordinatorDouble.stateCompletion!(.initial)

        XCTAssertNotNil(vc.children.first as? StartNowViewController)
    }
    
    func testPresentsPostcodeState() {
        let coordinatorDouble = OnboardingCoordinatorDouble()
        let vc = OnboardingViewController.instantiate()
        vc.inject(env: envDouble(), coordinator: coordinatorDouble, uiQueue: QueueDouble()) {}
        let container = ViewControllerContainerDouble()
        vc.showIn(container: container)

        vc.updateState()
        coordinatorDouble.stateCompletion!(.partialPostcode)

        XCTAssertNotNil(vc.children.first as? PostcodeViewController)
    }

    func testPresentsPermissionsState() {
        let coordinatorDouble = OnboardingCoordinatorDouble()
        let vc = OnboardingViewController.instantiate()
        vc.inject(env: envDouble(), coordinator: coordinatorDouble, uiQueue: QueueDouble()) {}
        let container = ViewControllerContainerDouble()
        vc.showIn(container: container)

        vc.updateState()
        coordinatorDouble.stateCompletion!(.permissions)

        XCTAssertNotNil(vc.children.first as? PermissionsViewController)
    }

    func testPresentsRegistrationState() {
        let coordinatorDouble = OnboardingCoordinatorDouble()
        let vc = OnboardingViewController.instantiate()
        vc.inject(env: envDouble(), coordinator: coordinatorDouble, uiQueue: QueueDouble()) {}
        let container = ViewControllerContainerDouble()
        vc.showIn(container: container)

        vc.updateState()
        coordinatorDouble.stateCompletion!(.initial)

        XCTAssertNotNil(vc.children.first as? StartNowViewController)
    }
    
    func envDouble() -> OnboardingEnvironment {
        return OnboardingEnvironment(persistence: PersistenceDouble(), authorizationManager: AuthorizationManagerDouble(), remoteNotificationManager: RemoteNotificationManagerDouble(), notificationCenter: NotificationCenter())
    }
}
