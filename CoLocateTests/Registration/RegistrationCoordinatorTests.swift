//
//  RegistrationStateMachineTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class RegistrationCoordinatorTests: TestCase {

    var coordinator: RegistrationCoordinator!

    let application = ApplicationDouble()
    let pushNotificationManager = PushNotificationManagerDouble()
    let registrationService = RegistrationServiceDouble()
    let registrationStorage = RegistrationStorageDouble()

    var navController: UINavigationController!
    
    override func setUp() {
        super.setUp()

        navController = UINavigationController()
        coordinator = RegistrationCoordinator(navController: navController,
                                              pushNotificationManager: pushNotificationManager,
                                              registrationService: registrationService,
                                              persistance: PersistanceDouble(),
                                              notificationCenter: NotificationCenter())
    }

    func test_first_screen_requests_push_notifications() {
        coordinator.start()

        let vc = navController.topViewController as? NotificationsPromptViewController
        XCTAssertNotNil(vc)
        XCTAssertNotNil(vc?.pushNotificationsRequester)
    }

    func test_notifies_caller_when_notificatons_are_allowed() {
        var didAllowNotifications = false
        coordinator.requestPushNotifications() { result in
            switch result {
            case .success(let granted):
                didAllowNotifications = granted
            default:
                didAllowNotifications = false
            }
        }

        pushNotificationManager.completion?(.success(true))
        XCTAssertTrue(didAllowNotifications)
    }

    func test_shows_bluetooth_after_push_notifications() {
        coordinator.requestPushNotifications() { _ in }
        XCTAssertNotNil(pushNotificationManager.completion)

        pushNotificationManager.completion?(.success(true))
        coordinator.advanceAfterPushNotifications()

        let vc = navController.topViewController as? PermissionsViewController

        XCTAssertNotNil(vc)
        XCTAssertNotNil(vc?.bluetoothReadyDelegate)
    }

    func test_shows_registration_after_bluetooth() {
        coordinator.bluetoothIsAvailable()

        let vc = navController.topViewController as? RegistrationViewController
        XCTAssertNotNil(vc)
        XCTAssertNotNil(vc?.pushNotificationManager)
        XCTAssertNotNil(vc?.registrationService)
    }
}
