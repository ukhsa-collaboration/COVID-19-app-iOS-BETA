//
//  RegistrationStateMachineTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class RegistrationCoordinatorTests: XCTestCase {

    var subject: RegistrationCoordinator!

    let application = ApplicationDouble()
    let delegate = RegistrationCooordinatorDelegateDouble()
    let notificationManager = NotificationManagerDouble()
    let registrationService = RegistrationServiceDouble()
    let registrationStorage = RegistrationStorageDouble()

    var navController: UINavigationController!

    let registration = Registration(id: UUID(uuidString: "39B84598-3AD8-4900-B4E0-EE868773181D")!, secretKey: Data())

    override func setUp() {
        super.setUp()

        navController = UINavigationController()

        subject = RegistrationCoordinator(application: application,
                                          navController: navController,
                                          notificationManager: notificationManager,
                                          registrationService: registrationService,
                                          registrationStorage: registrationStorage,
                                          delegate: delegate)
    }

    func test_first_screen_requests_push_notifications() {
        XCTAssertFalse(subject.isRegistered())

        subject.start()

        let vc = navController.topViewController as? NotificationsPromptViewController
        XCTAssertNotNil(vc)
        XCTAssertNotNil(vc?.pushNotificationsRequester)
    }

    func test_notifies_caller_when_notificatons_are_allowed() {
        var didAllowNotifications = false
        subject.requestPushNotifications() { result in
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
        subject.requestPushNotifications() { _ in }
        XCTAssertNotNil(notificationManager.completion)

        notificationManager.completion?(.success(true))
        subject.advanceAfterPushNotifications()

        let vc = navController.topViewController as? PermissionsPromptViewController

        XCTAssertNotNil(vc)
        XCTAssertNotNil(vc?.bluetoothReadyDelegate)

        XCTAssertFalse(subject.isRegistered())
    }

    func test_shows_registration_after_bluetooth() {
        subject.bluetoothIsAvailable()

        let vc = navController.topViewController as? RegistrationViewController
        XCTAssertNotNil(vc)
        XCTAssertNotNil(vc?.notificationManager)
        XCTAssertNotNil(vc?.registrationService)
        XCTAssertNotNil(vc?.delegate)

        XCTAssertFalse(subject.isRegistered())
    }

    func test_alerts_delegate_when_registration_is_complete() {
        subject = RegistrationCoordinator(application: application,
                                          navController: navController,
                                          notificationManager: notificationManager,
                                          registrationService: registrationService,
                                          registrationStorage: RegistrationStorageDouble(id: registration.id, key: registration.secretKey),
                                          delegate: delegate)

        subject.requestPushNotifications() { _ in }
        notificationManager.completion?(.success(true))
        subject.bluetoothIsAvailable()
        subject.registrationDidFinish(with: registration)

        XCTAssertTrue(subject.isRegistered())
        XCTAssertEqual(delegate.registration?.id, registration.id)
        XCTAssertEqual(delegate.registration?.secretKey, registration.secretKey)
    }

    func test_when_already_registered_calls_delegate_immediately() {
        let storageWithSavedRegistration = RegistrationStorageDouble(id: registration.id, key: registration.secretKey)

        subject = RegistrationCoordinator(application: application,
                                          navController: navController,
                                          notificationManager: notificationManager,
                                          registrationService: registrationService,
                                          registrationStorage: storageWithSavedRegistration,
                                          delegate: delegate)

        XCTAssertTrue(subject.isRegistered())
        XCTAssertNil(delegate.registration?.id)
        XCTAssertNil(delegate.registration?.secretKey)

        subject.start()
        XCTAssertEqual(delegate.registration?.id, registration.id)
        XCTAssertEqual(delegate.registration?.secretKey, registration.secretKey)
    }
}

class RegistrationCooordinatorDelegateDouble: RegistrationCoordinatorDelegate {
    var registration: Registration?

    func registrationDidFinish(with registration: Registration) {
        self.registration = registration
    }
}
