//
//  RemoteNotificationManagerDouble.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
@testable import Sonar

class RemoteNotificationManagerDouble: RemoteNotificationManager {
    let dispatcher: RemoteNotificationDispatching
    var pushToken: String?
    var handlers: [RemoteNotificationType : RemoteNotificationHandler] = [:]
    
    init(dispatcher: RemoteNotificationDispatching) {
        self.dispatcher = dispatcher
    }
    
    convenience init() {
        self.init(dispatcher: RemoteNotificationDispatcher(notificationCenter: NotificationCenter(), userNotificationCenter: UserNotificationCenterDouble()))
    }

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
