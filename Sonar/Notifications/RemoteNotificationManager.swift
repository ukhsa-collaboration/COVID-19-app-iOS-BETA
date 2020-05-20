//
//  RemoteNotificationManager.swift
//  Sonar
//
//  Created by NHSX on 3/25/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import UIKit

import Logging
import Firebase

// Send a notification when we receive a push token, since there might be mulltiple
// interested parties and we don't care what (if anything) they do.
let PushTokenReceivedNotification = NSNotification.Name("PushTokenReceivedNotification")

enum RemoteNotificationType {
    case registrationActivationCode
    case status
    case testResult
}

// Actual push/remote notifications are done via callback becasue we (or rather, AppDelegate)
// needs to know when all (potentially async) processing is done.
typealias RemoteNotificationCompletionHandler = (UIBackgroundFetchResult) -> Void;
typealias RemoteNotificationHandler = (_ userInfo: [AnyHashable : Any], _ completionHandler: @escaping RemoteNotificationCompletionHandler) -> Void


// Handles both push and remote notifiations.
protocol RemoteNotificationManager {
    var dispatcher: RemoteNotificationDispatching { get }

    var pushToken: String? { get }
    
    func configure()
    
    func registerHandler(forType: RemoteNotificationType, handler: @escaping RemoteNotificationHandler)
    func removeHandler(forType type: RemoteNotificationType)

    func requestAuthorization(completion: @escaping (Result<Bool, Error>) -> Void)
    
    func handleNotification(userInfo: [AnyHashable : Any], completionHandler: @escaping RemoteNotificationCompletionHandler)
}


class ConcreteRemoteNotificationManager: NSObject, RemoteNotificationManager {
    var pushToken: String? {
        get { dispatcher.pushToken }
    }

    private let firebase: TestableFirebaseApp.Type
    private let messagingFactory: () -> TestableMessaging
    private let userNotificationCenter: UserNotificationCenter
    private let notificationAcknowledger: NotificationAcknowledger
    let dispatcher: RemoteNotificationDispatching

    init(
        firebase: TestableFirebaseApp.Type,
        messagingFactory: @escaping () -> TestableMessaging,
        userNotificationCenter: UserNotificationCenter,
        notificationAcknowledger: NotificationAcknowledger,
        dispatcher: RemoteNotificationDispatching
    ) {
        self.firebase = firebase
        self.messagingFactory = messagingFactory
        self.userNotificationCenter = userNotificationCenter
        self.notificationAcknowledger = notificationAcknowledger
        self.dispatcher = dispatcher
        
        super.init()
    }

    func configure() {
        firebase.configure()
        messagingFactory().delegate = self
    }
    
    func registerHandler(forType type: RemoteNotificationType, handler: @escaping RemoteNotificationHandler) {
        dispatcher.registerHandler(forType: type, handler: handler)
    }
    
    func removeHandler(forType type: RemoteNotificationType) {
        dispatcher.removeHandler(forType: type)
    }

    func requestAuthorization(completion: @escaping (Result<Bool, Error>) -> Void) {
        // This should probably be moved elsewhere, since this
        // actually doesn't have anything to do with *remote*
        // notifications.
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
    
    func handleNotification(userInfo: [AnyHashable : Any], completionHandler: @escaping RemoteNotificationCompletionHandler) {
        let alreadyAcked = notificationAcknowledger.ack(userInfo: userInfo)

        if !alreadyAcked {
            logger.debug("Notification not yet ack'd. Dispatching to appropriate handler ...")
            dispatcher.handleNotification(userInfo: userInfo, completionHandler: completionHandler)
        } else {
            logger.debug("Notification was already ack'd. Calling completion handler")
            completionHandler(.noData)
        }
    }
}

extension ConcreteRemoteNotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {

        let apnsToken = Messaging.messaging().apnsToken?.map { String(format: "%02hhx", $0) }.joined()
        logger.debug("fcmToken: \(fcmToken)")
        logger.debug("apnsToken: \(String(describing: apnsToken))")

        dispatcher.receiveRegistrationToken(fcmToken: fcmToken)
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

// MARK: - Logging
private let logger = Logger(label: "Notifications")
