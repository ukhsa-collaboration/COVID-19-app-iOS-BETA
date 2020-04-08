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
        vc.rootViewController = rootViewController
        vc.onboardingCoordinator = coordinatorDouble
        vc.uiQueue = queue

        vc.updateState()
        coordinatorDouble.stateCompletion!(.initial)

        XCTAssertNotNil(rootViewController.presentedViewController)
        XCTAssertNotNil(vc.children.first as? StartNowViewController)
    }

    func testPresentsPermissionsState() {
        let coordinatorDouble = OnboardingCoordinatorDouble()
        let queue = QueueDouble()
        let vc = OnboardingViewController.instantiate()
        vc.rootViewController = rootViewController
        vc.onboardingCoordinator = coordinatorDouble
        vc.uiQueue = queue

        vc.updateState()
        coordinatorDouble.stateCompletion!(.permissions)

        XCTAssertNotNil(rootViewController.presentedViewController)
        XCTAssertNotNil(vc.children.first as? PermissionsViewController)
    }

    func testPresentsRegistrationState() {
        let coordinatorDouble = OnboardingCoordinatorDouble()
        let queue = QueueDouble()
        let vc = OnboardingViewController.instantiate()
        vc.rootViewController = rootViewController
        vc.onboardingCoordinator = coordinatorDouble
        vc.uiQueue = queue

        vc.updateState()
        coordinatorDouble.stateCompletion!(.registration)

        XCTAssertNotNil(rootViewController.presentedViewController)
        XCTAssertNotNil(vc.children.first as? RegistrationViewController)
    }

    func testCompletionState() {
        let coordinatorDouble = OnboardingCoordinatorDouble()
        let queue = QueueDouble()
        let vc = OnboardingViewController.instantiate()
        vc.rootViewController = rootViewController
        vc.onboardingCoordinator = coordinatorDouble
        vc.uiQueue = queue

        var callbackCount = 0
        vc.didComplete = {
            callbackCount += 1
        }
        vc.updateState()
        coordinatorDouble.stateCompletion!(nil)

        XCTAssertEqual(callbackCount, 1)
    }

}
