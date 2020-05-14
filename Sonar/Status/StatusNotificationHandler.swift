//
//  StatusNotificationHandler.swift
//  Sonar
//
//  Created by NHSX on 4/28/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

import Logging

// This naming is somewhat confusing, since in this application,
// "status" means blue/amber/red, but the backend sends us a
// notification with {"status": "Potential"} to alert us about a
// potential exposure. This class handles the notification and
// is where we convert from the server's terminology to ours.

class StatusNotificationHandler {

    let logger = Logger(label: "StatusNotificationHandler")

    let statusStateMachine: StatusStateMachining

    init(statusStateMachine: StatusStateMachining) {
        self.statusStateMachine = statusStateMachine
    }

    func handle(userInfo: [AnyHashable: Any], completion: @escaping RemoteNotificationCompletionHandler) {
        guard
            let status = userInfo["status"] as? String,
            status == "Potential"
        else {
            logger.warning("Received unexpected status from remote notification: '\(String(describing: userInfo["status"]))'")
            completion(.noData)
            return
        }

        statusStateMachine.exposed()
        completion(.newData)
    }

}
