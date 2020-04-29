//
//  RemoteNotificationDispatchingDouble.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

@testable import Sonar

class RemoteNotificationDispatchingDouble: RemoteNotificationDispatching {
    var pushToken: String?

    func registerHandler(forType type: RemoteNotificationType, handler: @escaping RemoteNotificationHandler) {
    }

    func removeHandler(forType type: RemoteNotificationType) {
    }

    func hasHandler(forType type: RemoteNotificationType) -> Bool {
        return true
    }

    var handledNotification = false
    func handleNotification(userInfo: [AnyHashable : Any], completionHandler: @escaping RemoteNotificationCompletionHandler) {
        handledNotification = true
    }

    func receiveRegistrationToken(fcmToken: String) {
    }
}
