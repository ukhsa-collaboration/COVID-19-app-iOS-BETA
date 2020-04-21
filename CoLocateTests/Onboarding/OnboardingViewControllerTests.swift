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
        XCTAssertNotNil(show(state: .initial) as? StartNowViewController)
    }
    
    func testPresentsPostcodeState() {
        XCTAssertNotNil(show(state: .partialPostcode) as? PostcodeViewController)
    }

    func testPresentsPermissionsState() {
        XCTAssertNotNil(show(state: .permissions) as? PermissionsViewController)
    }
    
    func testCallsCompletionInDoneState() {
        let coordinatorDouble = OnboardingCoordinatorDouble()
        let vc = OnboardingViewController.instantiate()
        var called = false
        vc.inject(env: envDouble(), coordinator: coordinatorDouble, uiQueue: QueueDouble()) {
            called = true
        }
        let container = ViewControllerContainerDouble()
        vc.showIn(container: container)

        vc.updateState()
        coordinatorDouble.stateCompletion!(.done)
        
        XCTAssertTrue(called)
    }
    
    func show(state: OnboardingCoordinator.State) -> UIViewController? {
        let coordinatorDouble = OnboardingCoordinatorDouble()
        let vc = OnboardingViewController.instantiate()
        vc.inject(env: envDouble(), coordinator: coordinatorDouble, uiQueue: QueueDouble()) {}
        let container = ViewControllerContainerDouble()
        vc.showIn(container: container)

        vc.updateState()
        coordinatorDouble.stateCompletion!(state)

        return vc.children.first
    }
    
    func envDouble() -> OnboardingEnvironment {
        return OnboardingEnvironment(persistence: PersistenceDouble(), authorizationManager: AuthorizationManagerDouble(), remoteNotificationManager: RemoteNotificationManagerDouble(), notificationCenter: NotificationCenter())
    }
}
