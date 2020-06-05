//
//  OnboardingViewControllerTests.swift
//  SonarTests
//
//  Created by NHSX on 4/1/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

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
    
    func testPresentsBluetoothDeniedState() {
        XCTAssertNotNil(show(state: .bluetoothDenied) as? BluetoothDeniedViewController)
    }
    
    func testPresentsBluetoothOffState() {
        XCTAssertNotNil(show(state: .bluetoothOff) as? BluetoothOffViewController)
    }
    
    func testCallsCompletionInDoneState() {
        let coordinatorDouble = OnboardingCoordinatorDouble()
        let vc = OnboardingViewController.instantiate()
        var called = false
        vc.inject(env: envDouble(), coordinator: coordinatorDouble, bluetoothNursery: BluetoothNurseryDouble(), uiQueue: QueueDouble()) {
            called = true
        }

        vc.loadViewIfNeeded()
        coordinatorDouble.stateCompletion!(.done)
        
        XCTAssertTrue(called)
    }
    
    func show(state: OnboardingCoordinator.State) -> UIViewController? {
        let coordinatorDouble = OnboardingCoordinatorDouble()
        let vc = OnboardingViewController.instantiate()
        vc.inject(env: envDouble(), coordinator: coordinatorDouble, bluetoothNursery: BluetoothNurseryDouble(), uiQueue: QueueDouble()) {}

        vc.loadViewIfNeeded()
        coordinatorDouble.stateCompletion!(state)

        return vc.children.first
    }
    
    func envDouble() -> OnboardingEnvironment {
        return OnboardingEnvironment(persistence: PersistenceDouble(), authorizationManager: AuthorizationManagerDouble(), remoteNotificationManager: RemoteNotificationManagerDouble(), notificationCenter: NotificationCenter())
    }
}
