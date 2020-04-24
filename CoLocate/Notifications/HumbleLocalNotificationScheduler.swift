//
//  HumbleLocalNotificationScheduler.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

protocol LocalNotificationScheduling {
    func scheduleLocalNotification(body: String, interval: TimeInterval, identifier: String, repeats: Bool)
}

struct HumbleLocalNotificationScheduler: LocalNotificationScheduling {
    private let userNotificationCenter: UserNotificationCenter
    
    init(userNotificationCenter: UserNotificationCenter) {
        self.userNotificationCenter = userNotificationCenter
    }

    func scheduleLocalNotification(body: String, interval: TimeInterval, identifier: String, repeats: Bool) {
        let content = UNMutableNotificationContent()
        content.body = body

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: repeats)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        userNotificationCenter.add(request, withCompletionHandler: nil)
    }
}
