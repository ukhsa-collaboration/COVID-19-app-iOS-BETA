//
//  RegistrationStateMachineTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class RegistrationCoordinatorTests: TestCase, RegistrationCoordinatorDelegate {

    var coordinator: RegistrationCoordinator!

    let application = ApplicationDouble()
    let notificationManager = NotificationManagerDouble()
    let registrationService = RegistrationServiceDouble()
    let registrationStorage = RegistrationStorageDouble()

    var navController: UINavigationController!
    var delegateRegistration: Registration?

    var registration: Registration!
    var persistance: PersistanceDouble!
    
    override func setUp() {
        super.setUp()

        navController = UINavigationController()
        registration = Registration(id: UUID(uuidString: "39B84598-3AD8-4900-B4E0-EE868773181D")!, secretKey: Data())
        persistance = PersistanceDouble()

        coordinator = RegistrationCoordinator(application: application,
                                          navController: navController,
                                          notificationManager: notificationManager,
                                          registrationService: registrationService,
                                          persistance: persistance,
                                          delegate: self)
        delegateRegistration = nil
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

        notificationManager.completion?(.success(true))
        XCTAssertTrue(didAllowNotifications)
    }

    func test_shows_bluetooth_after_push_notifications() {
        coordinator.requestPushNotifications() { _ in }
        XCTAssertNotNil(notificationManager.completion)

        notificationManager.completion?(.success(true))
        coordinator.advanceAfterPushNotifications()

        let vc = navController.topViewController as? BluetoothPermissionsViewController

        XCTAssertNotNil(vc)
        XCTAssertNotNil(vc?.bluetoothReadyDelegate)
    }

    func test_shows_registration_after_bluetooth() {
        coordinator.bluetoothIsAvailable()

        let vc = navController.topViewController as? RegistrationViewController
        XCTAssertNotNil(vc)
        XCTAssertNotNil(vc?.notificationManager)
        XCTAssertNotNil(vc?.registrationService)
        XCTAssertNotNil(vc?.delegate)
    }

    func test_alerts_delegate_when_registration_is_complete() {
        coordinator = RegistrationCoordinator(application: application,
                                          navController: navController,
                                          notificationManager: notificationManager,
                                          registrationService: registrationService,
                                          persistance: persistance,
                                          delegate: self)

        coordinator.requestPushNotifications() { _ in }
        notificationManager.completion?(.success(true))
        coordinator.bluetoothIsAvailable()
        coordinator.registrationDidFinish(with: registration)

        XCTAssertEqual(delegateRegistration?.id, registration.id)
        XCTAssertEqual(delegateRegistration?.secretKey, registration.secretKey)
    }

    func test_when_already_registered_calls_delegate_immediately() {
        persistance.registration = registration
        coordinator = RegistrationCoordinator(application: application,
                                          navController: navController,
                                          notificationManager: notificationManager,
                                          registrationService: registrationService,
                                          persistance: persistance,
                                          delegate: self)
        coordinator.start()
        
        XCTAssertEqual(delegateRegistration?.id, registration.id)
        XCTAssertEqual(delegateRegistration?.secretKey, registration.secretKey)
    }
    
    // MARK: -- RegistrationCoordinatorDelegate
    
    func didCompleteRegistration(_ registration: Registration) {
        self.delegateRegistration = registration
    }

}
