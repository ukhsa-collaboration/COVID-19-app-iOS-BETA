//
//  RegistrationReminderScheduler.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

protocol RegistrationReminderScheduler {
    func schedule()
    func cancel()
}

class ConcreteRegistrationReminderScheduler: RegistrationReminderScheduler {
    private let userNotificationCenter: UserNotificationCenter
    
    init(userNotificationCenter: UserNotificationCenter) {
        self.userNotificationCenter = userNotificationCenter
    }

    func schedule() {
        let notificationScheduler = HumbleLocalNotificationScheduler(userNotificationCenter: userNotificationCenter)
        let body = "Your registration has failed. Please open the app and select retry to complete your registration."
        notificationScheduler.scheduleLocalNotification(title: nil, body: body, interval: 24 * 60, identifier: identifier, repeats: true)
    }
    
    func cancel() {
        userNotificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
}

private let identifier = "registration.reminder"
