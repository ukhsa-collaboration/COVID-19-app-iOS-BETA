//
//  PushNotificationManagerDouble.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
@testable import CoLocate

class PushNotificationManagerDouble: PushNotificationManager {
    var pushToken: String?
    var handlers: [PushNotificationType : PushNotificationHandler] = [:]

    func configure() { }
    
    func registerHandler(forType type: PushNotificationType, handler: @escaping PushNotificationHandler) {
        handlers[type] = handler
    }
    
    func removeHandler(forType type: PushNotificationType) {
        handlers[type] = nil
    }

    var requestAuthorizationCompletion: ((Result<Bool, Error>) -> Void)?
    func requestAuthorization(completion: @escaping (Result<Bool, Error>) -> Void) {
        self.requestAuthorizationCompletion = completion
    }
    
    func handleNotification(userInfo: [AnyHashable : Any], completionHandler: @escaping PushNotificationCompletionHandler) {
    }
}
