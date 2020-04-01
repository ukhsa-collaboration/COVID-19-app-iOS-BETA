//
//  PushNotificationDispatcher.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

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


class PushNotificationDispatcher {
    static let shared = PushNotificationDispatcher()
    
    var pushToken: String?
    
    private var handlers = HandlerDictionary()
    private let notificationCenter: NotificationCenter
    private let userNotificationCenter: UserNotificationCenter
    private let persistence: Persistence
    
    init(notificationCenter: NotificationCenter, userNotificationCenter: UserNotificationCenter, persistence: Persistence) {
        self.notificationCenter = notificationCenter
        self.userNotificationCenter = userNotificationCenter
        self.persistence = persistence
    }
    
    convenience init() {
        self.init(
            notificationCenter: NotificationCenter.default,
            userNotificationCenter: UNUserNotificationCenter.current(),
            persistence: Persistence.shared
        )
    }

    func registerHandler(forType type: PushNotificationType, handler: @escaping PushNotificationHandler) {
        handlers[type] = handler
    }
    
    func removeHandler(forType type: PushNotificationType) {
        handlers[type] = nil
    }
    
    func hasHandler(forType type: PushNotificationType) -> Bool {
        return handlers.hasHandler(forType: type)
    }
    
    func handleNotification(userInfo: [AnyHashable : Any], completionHandler: @escaping PushNotificationCompletionHandler) {
        // TODO: Move this out of the push notification dispatcher?
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
    
    func receiveRegistrationToken(fcmToken: String) {
        pushToken = fcmToken
        notificationCenter.post(name: PushTokenReceivedNotification, object: nil, userInfo: nil)

        let apnsToken = Messaging.messaging().apnsToken?.map { String(format: "%02hhx", $0) }.joined()
        print("apnsToken: \(String(describing: apnsToken))")
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
    
    func hasHandler(forType type: PushNotificationType) -> Bool {
        return handlers[type] != nil
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
