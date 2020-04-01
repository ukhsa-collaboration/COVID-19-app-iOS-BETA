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

fileprivate enum RegisteredState : Int {
    case unregistered
    case notificationsAccepted
    case bluetoothAccepted
    case completed
}

class RegistrationCoordinator {

    let navController: UINavigationController
    let pushNotificationManager: PushNotificationManager
    let registrationService: RegistrationService
    let persistance: Persistance
    let notificationCenter: NotificationCenter

    fileprivate var currentState: RegisteredState = .unregistered

    init(navController: UINavigationController,
         pushNotificationManager: PushNotificationManager,
         registrationService: RegistrationService,
         persistance: Persistance,
         notificationCenter: NotificationCenter) {
        
        self.navController = navController
        self.pushNotificationManager = pushNotificationManager
        self.registrationService = registrationService
        self.persistance = persistance
        self.notificationCenter = notificationCenter
        
        notificationCenter.addObserver(self, selector: #selector(didReceiveNsNotification(notification:)), name: RegistrationCompleteNotification, object: nil)
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }

    func start() {
        navController.viewControllers = [nextViewController()]
    }

    func nextViewController() -> UIViewController {
        switch currentState {
            
        case .unregistered:
            let notificationsViewController = NotificationsPromptViewController.instantiate()
            notificationsViewController.pushNotificationsRequester = self

            return notificationsViewController

        case .notificationsAccepted:
            let permissionsViewController = PermissionsViewController.instantiate()
            permissionsViewController.bluetoothReadyDelegate = self

            return permissionsViewController

        default:
            let registrationViewController = RegistrationViewController.instantiate()

            registrationViewController.registrationService = registrationService
            registrationViewController.pushNotificationManager = pushNotificationManager

            return registrationViewController
        }
    }
    
    @objc private func didReceiveNsNotification(notification: NSNotification) {
        self.currentState = .completed
    }
}

extension RegistrationCoordinator: PushNotificationRequester {
    func requestPushNotifications(completion: @escaping (Result<Bool, Error>) -> Void) {
        pushNotificationManager.requestAuthorization { (result) in
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
