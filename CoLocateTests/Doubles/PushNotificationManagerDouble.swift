//
//  RemoteNotificationManagerDouble.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
@testable import CoLocate

class RemoteNotificationManagerDouble: RemoteNotificationManager {
    var pushToken: String?
    var handlers: [RemoteNotificationType : RemoteNotificationHandler] = [:]

    func configure() { }
    
    func registerHandler(forType type: RemoteNotificationType, handler: @escaping RemoteNotificationHandler) {
        handlers[type] = handler
    }
    
    func removeHandler(forType type: RemoteNotificationType) {
        handlers[type] = nil
    }

    var requestAuthorizationCompletion: ((Result<Bool, Error>) -> Void)?
    func requestAuthorization(completion: @escaping (Result<Bool, Error>) -> Void) {
        self.requestAuthorizationCompletion = completion
    }
    
    func handleNotification(userInfo: [AnyHashable : Any], completionHandler: @escaping RemoteNotificationCompletionHandler) {
    }
}
