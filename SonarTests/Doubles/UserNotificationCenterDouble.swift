//
//  UserNotificationCenterDouble.swift
//  SonarTests
//
//  Created by NHSX on 4/1/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

@testable import Sonar

class UserNotificationCenterDouble: UserNotificationCenter {

    weak var delegate: UNUserNotificationCenterDelegate?

    var options: UNAuthorizationOptions?
    var requestAuthCompletionHandler: ((Bool, Error?) -> Void)?
    func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping (Bool, Error?) -> Void) {
        self.options = options
        self.requestAuthCompletionHandler = completionHandler
    }

    var requests: [UNNotificationRequest] = []
    var addCompletionHandler: ((Error?) -> Void)?
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?) {
        self.requests.append(request)
        self.addCompletionHandler = completionHandler
    }

    var removedIdentifiers: [String]?
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedIdentifiers = identifiers
        requests = requests.filter({ !identifiers.contains($0.identifier) })
    }
}
