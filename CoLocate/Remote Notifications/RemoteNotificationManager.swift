//
//  RemoteNotificationManager.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import UIKit

import Firebase

// Send a notification when we receive a push token, since there might be mulltiple
// interested parties and we don't care what (if anything) they do.
let PushTokenReceivedNotification = NSNotification.Name("PushTokenReceivedNotification")

enum RemoteNotificationType {
    case registrationActivationCode
    case statusChange
}

// Actual push/remote notifications are done via callback becasue we (or rather, AppDelegate)
// needs to know when all (potentially async) processing is done.
typealias RemoteNotificationCompletionHandler = (UIBackgroundFetchResult) -> Void;
typealias RemoteNotificationHandler = (_ userInfo: [AnyHashable : Any], _ completionHandler: @escaping RemoteNotificationCompletionHandler) -> Void


// Handles both push and remote notifiations.
protocol RemoteNotificationManager {
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

    static let shared = ConcreteRemoteNotificationManager()

    private let firebase: TestableFirebaseApp.Type
    private let messagingFactory: () -> TestableMessaging
    private let userNotificationCenter: UserNotificationCenter
    private let notificationCenter: NotificationCenter
    private let dispatcher: RemoteNotificationDispatcher

    init(
        firebase: TestableFirebaseApp.Type,
        messagingFactory: @escaping () -> TestableMessaging,
        userNotificationCenter: UserNotificationCenter,
        notificationCenter: NotificationCenter,
        dispatcher: RemoteNotificationDispatcher
    ) {
        self.firebase = firebase
        self.messagingFactory = messagingFactory
        self.userNotificationCenter = userNotificationCenter
        self.notificationCenter = notificationCenter
        self.dispatcher = dispatcher
        
        super.init()
    }

    convenience override init() {
        self.init(
            firebase: FirebaseApp.self,
            messagingFactory: { Messaging.messaging() },
            userNotificationCenter: UNUserNotificationCenter.current(),
            notificationCenter: NotificationCenter.default,
            dispatcher: RemoteNotificationDispatcher.shared
        )
    }
    
    convenience init(
        firebase: TestableFirebaseApp.Type,
        messagingFactory: @escaping () -> TestableMessaging,
        userNotificationCenter: UserNotificationCenter,
        notificationCenter: NotificationCenter,
        persistence: Persistence
    ) {
        self.init(
            firebase: firebase,
            messagingFactory: messagingFactory,
            userNotificationCenter: userNotificationCenter,
            notificationCenter: notificationCenter,
            dispatcher: RemoteNotificationDispatcher(
                notificationCenter: notificationCenter,
                userNotificationCenter: userNotificationCenter,
                persistence: persistence
            )
        )
    }

    func configure() {
        firebase.configure()
        messagingFactory().delegate = self
        userNotificationCenter.delegate = self
    }
    
    func registerHandler(forType type: RemoteNotificationType, handler: @escaping RemoteNotificationHandler) {
        dispatcher.registerHandler(forType: type, handler: handler)
    }
    
    func removeHandler(forType type: RemoteNotificationType) {
        dispatcher.removeHandler(forType: type)
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
    
    func handleNotification(userInfo: [AnyHashable : Any], completionHandler: @escaping RemoteNotificationCompletionHandler) {
        dispatcher.handleNotification(userInfo: userInfo, completionHandler: completionHandler)
    }
}

extension ConcreteRemoteNotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // This only happens when we are in the foregrond?
        
        handleNotification(userInfo: notification.request.content.userInfo) {_ in }

        // How to re-present notification?
//        completionHandler([.alert, .badge, .sound])
    }
}

extension ConcreteRemoteNotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("fcmToken: \(fcmToken)")
        let apnsToken = Messaging.messaging().apnsToken?.map { String(format: "%02hhx", $0) }.joined()
        print("apnsToken: \(String(describing: apnsToken))")
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
