//
//  StatusNotificationHandler.swift
//  Sonar
//
//  Created by NHSX on 4/28/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

import Logging

class ExposedNotificationHandler {
    
    private let logger = Logger(label: "StatusNotificationHandler")
    private let dateFormatter = ISO8601DateFormatter()

    private let statusStateMachine: StatusStateMachining
    private let dateProvider: () -> Date

    init(
        statusStateMachine: StatusStateMachining,
        dateProvider: @escaping () -> Date = { Date() }
    ) {
        self.statusStateMachine = statusStateMachine
        self.dateProvider = dateProvider
    }
    
    func handle(userInfo: [AnyHashable: Any], completion: @escaping RemoteNotificationCompletionHandler) {
        guard let status = userInfo["status"] as? String, status == "Potential" else {
            logger.warning("Received unexpected status from remote notification: '\(String(describing: userInfo["status"]))'")
            completion(.noData)
            return
        }

        let mostRecentProximityEventDate = userInfo["mostRecentProximityEventDate"] as? String
        let exposedDate = mostRecentProximityEventDate.flatMap({ dateFormatter.date(from: $0) })
        statusStateMachine.exposed(on: exposedDate ?? dateProvider())

        completion(.newData)
    }

}
