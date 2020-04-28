//
//  StatusNotificationHandler.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

import Logging

let PotentiallyExposedNotification = NSNotification.Name("PotentiallyExposedNotification")

// This naming is somewhat confusing, since in this application,
// "status" means blue/amber/red, but the backend sends us a
// notification with {"status": "Potential"} to alert us about a
// potential exposure. This class handles the notification and
// is where we convert from the server's terminology to ours.

class StatusNotificationHandler {

    let logger = Logger(label: "StatusNotificationHandler")

    let persisting: Persisting
    let userNotificationCenter: UserNotificationCenter
    let notificationCenter: NotificationCenter
    let currentDateProvider: () -> Date

    init(
        persisting: Persisting,
        userNotificationCenter: UserNotificationCenter,
        notificationCenter: NotificationCenter,
        currentDateProvider: @escaping () -> Date = { Date() }
    ) {
        self.persisting = persisting
        self.userNotificationCenter = userNotificationCenter
        self.notificationCenter = notificationCenter
        self.currentDateProvider = currentDateProvider
    }

    func handle(userInfo: [AnyHashable: Any]) {
        guard
            let status = userInfo["status"] as? String,
            status == "Potential"
        else {
            logger.warning("Received unexpected status from remote notification: '\(String(describing: userInfo["status"]))'")
            return
        }

        persisting.potentiallyExposed = currentDateProvider()
        sendUserNotification()
        notificationCenter.post(name: PotentiallyExposedNotification, object: self)
    }

    private func sendUserNotification() {
        let content = UNMutableNotificationContent()
        content.title = "POTENTIAL_STATUS_TITLE".localized
        content.body = "POTENTIAL_STATUS_BODY".localized

        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: nil)

        userNotificationCenter.add(request) { error in
            if error != nil {
                self.logger.critical("Unable to add local notification: \(String(describing: error))")
            }
        }
    }

}
