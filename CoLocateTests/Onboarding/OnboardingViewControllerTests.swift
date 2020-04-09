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
        let queue = QueueDouble()
        let vc = OnboardingViewController.instantiate()
        vc.inject(env: envDouble(), coordinator: coordinatorDouble) {}
        let rootViewController = RootViewController()
        parentViewControllerForTests.addChild(rootViewController)
        vc.showIn(rootViewController: rootViewController)
        vc.uiQueue = queue

        vc.updateState()
        coordinatorDouble.stateCompletion!(.initial)

        XCTAssertEqual(rootViewController.children.count, 1)
        XCTAssertNotNil(vc.children.first as? StartNowViewController)
    }

    func testPresentsPermissionsState() {
        let coordinatorDouble = OnboardingCoordinatorDouble()
        let queue = QueueDouble()
        let vc = OnboardingViewController.instantiate()
        vc.inject(env: envDouble(), coordinator: coordinatorDouble) {}
        let rootViewController = RootViewController()
        parentViewControllerForTests.addChild(rootViewController)
        vc.showIn(rootViewController: rootViewController)
        vc.uiQueue = queue

        vc.updateState()
        coordinatorDouble.stateCompletion!(.permissions)

        XCTAssertEqual(rootViewController.children.count, 1)
        XCTAssertNotNil(vc.children.first as? PermissionsViewController)
    }

    func testPresentsRegistrationState() {
        let coordinatorDouble = OnboardingCoordinatorDouble()
        let queue = QueueDouble()
        let vc = OnboardingViewController.instantiate()
        vc.inject(env: envDouble(), coordinator: coordinatorDouble) {}
        let rootViewController = RootViewController()
        parentViewControllerForTests.addChild(rootViewController)
        vc.showIn(rootViewController: rootViewController)
        vc.uiQueue = queue

        vc.updateState()
        coordinatorDouble.stateCompletion!(.initial)

        XCTAssertEqual(rootViewController.children.count, 1)
        XCTAssertNotNil(vc.children.first as? StartNowViewController)
    }
    
    func envDouble() -> OnboardingEnvironment {
        return OnboardingEnvironment(persistence: PersistenceDouble(), authorizationManager: AuthorizationManagerDouble(), remoteNotificationManager: RemoteNotificationManagerDouble())
    }
}
