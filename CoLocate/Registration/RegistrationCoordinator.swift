//
//  File.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

protocol PushNotificationRequester {
    func requestPushNotifications(completion: @escaping (Result<Bool, Error>) -> Void)
    func advanceAfterPushNotifications()
}

protocol BluetoothAvailableDelegate {
    func bluetoothIsAvailable()
}

protocol RegistrationSavedDelegate {
    func registrationDidFinish(with registration: Registration)
}

protocol RegistrationCoordinatorDelegate {
    func didCompleteRegistration(_ registration: Registration)
}

fileprivate enum RegisteredState : Int {
    case unregistered
    case notificationsAccepted
    case bluetoothAccepted
    case completed
}

class RegistrationCoordinator {

    let application: Application
    let navController: UINavigationController
    let notificationManager: NotificationManager
    let registrationService: RegistrationService
    let persistance: Persistance
    let delegate: RegistrationCoordinatorDelegate

    fileprivate var currentState: RegisteredState = .unregistered

    init(application: Application,
         navController: UINavigationController,
         notificationManager: NotificationManager,
         registrationService: RegistrationService,
         persistance: Persistance,
         delegate: RegistrationCoordinatorDelegate) {
        self.delegate = delegate
        self.application = application
        self.navController = navController
        self.notificationManager = notificationManager
        self.registrationService = registrationService
        self.persistance = persistance
    }

    func start() {
        if let registration = persistance.registration {
            delegate.didCompleteRegistration(registration)
        } else {
            navController.viewControllers = [nextViewController()]
        }
    }

    func nextViewController() -> UIViewController {
        switch currentState {
            
        case .unregistered:
            let notificationsViewController = NotificationsPromptViewController.instantiate()
            notificationsViewController.pushNotificationsRequester = self

            return notificationsViewController

        case .notificationsAccepted:
            let bluetoothPermissionsViewController = BluetoothPermissionsViewController.instantiate()
            bluetoothPermissionsViewController.bluetoothReadyDelegate = self

            return bluetoothPermissionsViewController

        default:
            let registrationViewController = RegistrationViewController.instantiate()

            registrationViewController.delegate = self
            registrationViewController.registrationService = registrationService
            registrationViewController.notificationManager = notificationManager

            return registrationViewController
        }
    }
}

extension RegistrationCoordinator: PushNotificationRequester {
    func requestPushNotifications(completion: @escaping (Result<Bool, Error>) -> Void) {
        notificationManager.requestAuthorization(application: application) { (result) in
            switch result {
            case .success(let granted):
                guard granted else {
                    completion(.success(granted))
                    return
                }

                self.currentState = .notificationsAccepted
                completion(.success(granted))

                break

            case .failure(let error):
                completion(.failure(error))

                print("User did not grant notifications")
                break
            }
        }
    }

    func advanceAfterPushNotifications() {
        self.navController.pushViewController(self.nextViewController(), animated: true)
    }
}

extension RegistrationCoordinator: BluetoothAvailableDelegate {
    func bluetoothIsAvailable() {
        self.currentState = .bluetoothAccepted

        self.navController.pushViewController(self.nextViewController(), animated: true)
    }
}

extension RegistrationCoordinator: RegistrationSavedDelegate {
    
    func registrationDidFinish(with registration: Registration) {
        self.currentState = .completed

        delegate.didCompleteRegistration(registration)
    }

}
