//
//  PushNotificationManager.swift
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

enum PushNotificationType {
    case registrationActivationCode
    case statusChange
}

// Actual push/remote notifications are done via callback becasue we (or rather, AppDelegate)
// needs to know when all (potentially async) processing is done.
typealias PushNotificationCompletionHandler = (UIBackgroundFetchResult) -> Void;
typealias PushNotificationHandler = (_ userInfo: [AnyHashable : Any], _ completionHandler: @escaping PushNotificationCompletionHandler) -> Void


// Handles both push and remote notifiations.
protocol PushNotificationManager {
    var pushToken: String? { get }
    
    func configure()
    
    func registerHandler(forType: PushNotificationType, handler: @escaping PushNotificationHandler)
    func removeHandler(forType type: PushNotificationType)

    func requestAuthorization(completion: @escaping (Result<Bool, Error>) -> Void)
    
    func handleNotification(userInfo: [AnyHashable : Any], completionHandler: @escaping PushNotificationCompletionHandler)
}


class ConcretePushNotificationManager: NSObject, PushNotificationManager {

    static let shared = ConcretePushNotificationManager()

    let firebase: TestableFirebaseApp.Type
    let messagingFactory: () -> TestableMessaging
    let userNotificationCenter: UserNotificationCenter
    let notificationCenter: NotificationCenter
    let persistence: Persistence
    private var handlers = HandlerDictionary()
    
    var pushToken: String?

    init(
        firebase: TestableFirebaseApp.Type,
        messagingFactory: @escaping () -> TestableMessaging,
        userNotificationCenter: UserNotificationCenter,
        notificationCenter: NotificationCenter,
        persistence: Persistence
    ) {
        self.firebase = firebase
        self.messagingFactory = messagingFactory
        self.userNotificationCenter = userNotificationCenter
        self.notificationCenter = notificationCenter
        self.persistence = persistence

        super.init()
    }

    convenience override init() {
        self.init(
            firebase: FirebaseApp.self,
            messagingFactory: { Messaging.messaging() },
            userNotificationCenter: UNUserNotificationCenter.current(),
            notificationCenter: NotificationCenter.default,
            persistence: Persistence.shared
        )
    }

    func configure() {
        firebase.configure()
        messagingFactory().delegate = self
        userNotificationCenter.delegate = self
    }
    
    func registerHandler(forType type: PushNotificationType, handler: @escaping PushNotificationHandler) {
        handlers[type] = handler
    }
    
    func removeHandler(forType type: PushNotificationType) {
        handlers[type] = nil
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
    
    func handleNotification(userInfo: [AnyHashable : Any], completionHandler: @escaping PushNotificationCompletionHandler) {
        
        // TODO: Move this out of the push notification manager?
        if let status = userInfo["status"] {
            handleStatusUpdated(status: status)
            return
        }
        
        guard let type = notificationType(userInfo: userInfo) else {
            print("Warning: unrecognized notification with user info: \(userInfo)")
            completionHandler(.failed)
            return
        }
        
        print("Push notification is a \(type)")
        
        guard let handler = handlers[type] else {
            completionHandler(.failed)
            return
        }
        
        print("Got a handler")
        
        handler(userInfo, completionHandler)
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

            persistence.diagnosis = .potential
        } else {
            print("Received unexpected status from remote notification: '\(status)'")
        }
    }
    
    private func notificationType(userInfo: [AnyHashable : Any]) -> PushNotificationType? {
        if userInfo["activationCode"] as? String != nil {
            return .registrationActivationCode
        } else if userInfo["status"] as? String != nil {
            return .statusChange
        } else {
            return nil
        }
    }
}

extension ConcretePushNotificationManager: UNUserNotificationCenterDelegate {
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

extension ConcretePushNotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("fcmToken: \(fcmToken)")
        pushToken = fcmToken
        notificationCenter.post(name: PushTokenReceivedNotification, object: nil, userInfo: nil)

        let apnsToken = Messaging.messaging().apnsToken?.map { String(format: "%02hhx", $0) }.joined()
        print("apnsToken: \(String(describing: apnsToken))")
    }

}

private class HandlerDictionary {
    private var handlers: [PushNotificationType : PushNotificationHandler] = [:]
    
    subscript(index: PushNotificationType) -> PushNotificationHandler? {
        get {
            let handler = handlers[index]
            
            if handler == nil {
                complainAboutMissingHandler(type: index)
            }
            
            return handler
        }
        set {
            if newValue != nil && handlers[index] != nil {
                complainAboutHandlerReplacement(type: index)
            }
            
            handlers[index] = newValue
        }
    }
    
    private func complainAboutMissingHandler(type: PushNotificationType) {
        #if DEBUG
        fatalError("PushNotificationHandlerDictionary: no handler for notification type \(type)")
        #else
        print("Warning: PushNotificationHandlerDictionary: no handler for notification type \(type)")
        #endif
    }
    
    private func complainAboutHandlerReplacement(type: PushNotificationType) {
        #if DEBUG
        fatalError("PushNotificationHandlerDictionary: attempted to replace handler for \(type)")
        #else
        print("Warning: PushNotificationHandlerDictionary replacing existing handler for \(type)")
        #endif
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
