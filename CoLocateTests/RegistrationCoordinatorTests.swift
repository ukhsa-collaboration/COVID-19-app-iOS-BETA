//
//  RegistrationStateMachineTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class RegistrationCoordinatorTests: XCTestCase, RegistrationCoordinatorDelegate {

    var coordinator: RegistrationCoordinator!

    let application = ApplicationDouble()
    let notificationManager = NotificationManagerDouble()
    let registrationService = RegistrationServiceDouble()
    let registrationStorage = RegistrationStorageDouble()

    var navController: UINavigationController!
    var delegateRegistration: Registration?

    var registration: Registration!
    var storageWithSavedRegistration: RegistrationStorageDouble!
    
    override func setUp() {
        super.setUp()

        navController = UINavigationController()
        registration = Registration(id: UUID(uuidString: "39B84598-3AD8-4900-B4E0-EE868773181D")!, secretKey: Data())
        storageWithSavedRegistration = RegistrationStorageDouble(id: registration.id, key: registration.secretKey)

        coordinator = RegistrationCoordinator(application: application,
                                          navController: navController,
                                          notificationManager: notificationManager,
                                          registrationService: registrationService,
                                          registrationStorage: registrationStorage,
                                          delegate: self)
    }

    func test_first_screen_requests_push_notifications() {
        XCTAssertFalse(coordinator.isRegistered())

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

        notificationManager.completion?(.success(true))
        XCTAssertTrue(didAllowNotifications)
    }

    func test_shows_bluetooth_after_push_notifications() {
        coordinator.requestPushNotifications() { _ in }
        XCTAssertNotNil(notificationManager.completion)

        notificationManager.completion?(.success(true))
        coordinator.advanceAfterPushNotifications()

        let vc = navController.topViewController as? PermissionsPromptViewController

        XCTAssertNotNil(vc)
        XCTAssertNotNil(vc?.bluetoothReadyDelegate)

        XCTAssertFalse(coordinator.isRegistered())
    }

    func test_shows_registration_after_bluetooth() {
        coordinator.bluetoothIsAvailable()

        let vc = navController.topViewController as? RegistrationViewController
        XCTAssertNotNil(vc)
        XCTAssertNotNil(vc?.notificationManager)
        XCTAssertNotNil(vc?.registrationService)
        XCTAssertNotNil(vc?.delegate)

        XCTAssertFalse(coordinator.isRegistered())
    }

    func test_alerts_delegate_when_registration_is_complete() {
        coordinator = RegistrationCoordinator(application: application,
                                          navController: navController,
                                          notificationManager: notificationManager,
                                          registrationService: registrationService,
                                          registrationStorage: storageWithSavedRegistration,
                                          delegate: self)

        coordinator.requestPushNotifications() { _ in }
        notificationManager.completion?(.success(true))
        coordinator.bluetoothIsAvailable()
        coordinator.registrationDidFinish(with: registration)

        XCTAssertTrue(coordinator.isRegistered())
        XCTAssertEqual(delegateRegistration?.id, registration.id)
        XCTAssertEqual(delegateRegistration?.secretKey, registration.secretKey)
    }

    func test_when_already_registered_calls_delegate_immediately() {
        coordinator = RegistrationCoordinator(application: application,
                                          navController: navController,
                                          notificationManager: notificationManager,
                                          registrationService: registrationService,
                                          registrationStorage: storageWithSavedRegistration,
                                          delegate: self)

        XCTAssertTrue(coordinator.isRegistered())
        XCTAssertNil(delegateRegistration?.id)
        XCTAssertNil(delegateRegistration?.secretKey)

        coordinator.start()
        XCTAssertEqual(delegateRegistration?.id, registration.id)
        XCTAssertEqual(delegateRegistration?.secretKey, registration.secretKey)
    }
    
    // MARK: -- RegistrationCoordinatorDelegate
    
    func didCompleteRegistration(_ registration: Registration) {
        self.delegateRegistration = registration
    }

    
}
