//
//  RemoteNotificationDispatcher.swift
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


class RemoteNotificationDispatcher {
    static let shared = RemoteNotificationDispatcher()
    
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
        // TODO: Move this out of the dispatcher?
        if let status = userInfo["status"] {
            handleStatusUpdated(status: status)
            return
        }
        
        guard let type = notificationType(userInfo: userInfo) else {
            print("Warning: unrecognized notification with user info: \(userInfo)")
            completionHandler(.failed)
            return
        }
        
        print("Remote notification is a \(type)")
        
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
    
    private func notificationType(userInfo: [AnyHashable : Any]) -> RemoteNotificationType? {
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
        #if DEBUG
        fatalError("Remote notification HandlerDictionary: no handler for notification type \(type)")
        #else
        print("Warning: Remote notification HandlerDictionary: no handler for notification type \(type)")
        #endif
    }
    
    private func complainAboutHandlerReplacement(type: RemoteNotificationType) {
        #if DEBUG
        fatalError("Remote notification HandlerDictionary: attempted to replace handler for \(type)")
        #else
        print("Warning: Remote notification HandlerDictionary replacing existing handler for \(type)")
        #endif
    }
}
