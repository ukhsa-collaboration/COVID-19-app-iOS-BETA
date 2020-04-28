//
//  NotificationManager.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import UIKit

import Firebase

protocol NotificationManagerDelegate: class {
    func notificationManager(_ notificationManager: PushNotificationManager, didReceiveNotificationWithInfo userInfo: [AnyHashable : Any])
}

protocol PushNotificationManager {
    var pushToken: String? { get }
    
    var delegate: NotificationManagerDelegate? { get set }

    func configure()

    func requestAuthorization(completion: @escaping (Result<Bool, Error>) -> Void)
    
    func handleNotification(userInfo: [AnyHashable : Any])
}


class ConcreteNotificationManager: NSObject, PushNotificationManager {

    let firebase: TestableFirebaseApp.Type
    let messagingFactory: () -> TestableMessaging
    let userNotificationCenter: UserNotificationCenter
    let persistance: Persistance
    
    var pushToken: String?
    
    weak var delegate: NotificationManagerDelegate?

    init(
        firebase: TestableFirebaseApp.Type,
        messagingFactory: @escaping () -> TestableMessaging,
        userNotificationCenter: UserNotificationCenter,
        persistance: Persistance
    ) {
        self.firebase = firebase
        self.messagingFactory = messagingFactory
        self.userNotificationCenter = userNotificationCenter
        self.persistance = persistance

        super.init()
    }

    convenience override init() {
        self.init(
            firebase: FirebaseApp.self,
            messagingFactory: { Messaging.messaging() },
            userNotificationCenter: UNUserNotificationCenter.current(),
            persistance: Persistance.shared
        )
    }

    func configure() {
        firebase.configure()
        messagingFactory().delegate = self
        userNotificationCenter.delegate = self
    }

    func requestAuthorization(completion: @escaping (Result<Bool, Error>) -> Void) {
        userNotificationCenter.requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            completion(.success(granted))
        }
    }
    
    func handleNotification(userInfo: [AnyHashable : Any]) {
        if let status = userInfo["status"] {
            handleStatusUpdated(status: status)
            return
        }

        self.delegate?.notificationManager(self, didReceiveNotificationWithInfo: userInfo)
    }

    private func handleStatusUpdated(status: Any) {
        if status as? String == "Potential" {
            let content = UNMutableNotificationContent()
            content.title = "POTENTIAL_STATUS_TITLE".localized
            content.body = "POTENTIAL_STATUS_BODY".localized

            let uuidString = UUID().uuidString
            let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: nil)

            userNotificationCenter.add(request) { error in
                if error != nil {
                    print("Unable to add local notification: \(String(describing: error))")
                }
            }

            persistance.diagnosis = .potential
        } else {
            print("Received unexpected status from remote notification: '\(status)'")
        }
    }
}

extension ConcreteNotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // This only happens when we are in the foregrond?

        handleNotification(userInfo: notification.request.content.userInfo)

        // How to re-present notification?
//        completionHandler([.alert, .badge, .sound])
    }
}

extension ConcreteNotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("fcmToken: \(fcmToken)")
        pushToken = fcmToken
        delegate?.notificationManager(self, didReceiveNotificationWithInfo: ["pushToken": pushToken as Any])

        let apnsToken = Messaging.messaging().apnsToken?.map { String(format: "%02hhx", $0) }.joined()
        print("apnsToken: \(String(describing: apnsToken))")
    }

}

// MARK: - Testable

protocol Application {
    func registerForRemoteNotifications()
}

extension UIApplication: Application {
}

protocol TestableFirebaseApp {
    static func configure()
}

extension FirebaseApp: TestableFirebaseApp {
}

protocol TestableMessaging: class {
    var delegate: MessagingDelegate? { get set }
}

extension Messaging: TestableMessaging {
}

protocol UserNotificationCenter: class {
    var delegate: UNUserNotificationCenterDelegate? { get set }

    func requestAuthorization(
        options: UNAuthorizationOptions,
        completionHandler: @escaping (Bool, Error?) -> Void
    )

    func add(
        _ request: UNNotificationRequest,
        withCompletionHandler completionHandler: ((Error?) -> Void)?
    )
}

extension UNUserNotificationCenter: UserNotificationCenter {
}