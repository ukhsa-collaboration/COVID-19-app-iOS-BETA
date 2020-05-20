//
//  RemoteNotificationDispatcher.swift
//  Sonar
//
//  Created by NHSX on 4/1/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

import Logging

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
    
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])

}

extension UNUserNotificationCenter: UserNotificationCenter {
}

protocol RemoteNotificationDispatching {
    var pushToken: String? { get }

    func registerHandler(forType type: RemoteNotificationType, handler: @escaping RemoteNotificationHandler)
    func removeHandler(forType type: RemoteNotificationType)

    func hasHandler(forType type: RemoteNotificationType) -> Bool
    func handleNotification(userInfo: [AnyHashable : Any], completionHandler: @escaping RemoteNotificationCompletionHandler)

    func receiveRegistrationToken(fcmToken: String)
}


class RemoteNotificationDispatcher: RemoteNotificationDispatching {
    var pushToken: String?
    
    private var handlers = HandlerDictionary()
    private let notificationCenter: NotificationCenter
    private let userNotificationCenter: UserNotificationCenter
    
    init(notificationCenter: NotificationCenter, userNotificationCenter: UserNotificationCenter) {
        self.notificationCenter = notificationCenter
        self.userNotificationCenter = userNotificationCenter
    }

    func registerHandler(forType type: RemoteNotificationType, handler: @escaping RemoteNotificationHandler) {
        handlers[type] = handler
    }
    
    func removeHandler(forType type: RemoteNotificationType) {
        handlers[type] = nil
    }
    
    func hasHandler(forType type: RemoteNotificationType) -> Bool {
        return handlers.hasHandler(forType: type)
    }
    
    func handleNotification(userInfo: [AnyHashable : Any], completionHandler: @escaping RemoteNotificationCompletionHandler) {
        guard let type = notificationType(userInfo: userInfo) else {
            logger.warning("unrecognized notification with user info: \(userInfo)")
            completionHandler(.failed)
            return
        }
        
        logger.debug("Remote notification is a \(type)")
        
        guard let handler = handlers[type] else {
            logger.warning("No registered handler for type \(type)")
            completionHandler(.failed)
            return
        }
        
        handler(userInfo, completionHandler)
    }
    
    func receiveRegistrationToken(fcmToken: String) {
        pushToken = fcmToken
        notificationCenter.post(name: PushTokenReceivedNotification, object: fcmToken, userInfo: nil)
    }
    
    private func notificationType(userInfo: [AnyHashable : Any]) -> RemoteNotificationType? {
        if userInfo["activationCode"] as? String != nil {
            return .registrationActivationCode
        } else if userInfo["status"] as? String != nil {
            return .status
        } else if userInfo["result"] as? String != nil {
            return .testResult
        } else {
            return nil
        }
    }
}

private class HandlerDictionary {
    private var handlers: [RemoteNotificationType : RemoteNotificationHandler] = [:]
    
    subscript(index: RemoteNotificationType) -> RemoteNotificationHandler? {
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
    
    func hasHandler(forType type: RemoteNotificationType) -> Bool {
        return handlers[type] != nil
    }
    
    private func complainAboutMissingHandler(type: RemoteNotificationType) {
        logger.warning("Remote notification HandlerDictionary: no handler for notification type \(type)")
        assertionFailure("Remote notification HandlerDictionary: no handler for notification type \(type)")
    }
    
    private func complainAboutHandlerReplacement(type: RemoteNotificationType) {
        logger.warning("Remote notification HandlerDictionary replacing existing handler for \(type)")
        assertionFailure("Remote notification HandlerDictionary: attempted to replace handler for \(type)")
    }

}

private let logger = Logger(label: "Notifications")
