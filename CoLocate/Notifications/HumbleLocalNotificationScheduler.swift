//
//  HumbleLocalNotificationScheduler.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct HumbleLocalNotificationScheduler: LocalNotificationScheduling {
    static let shared = HumbleLocalNotificationScheduler()

    func scheduleLocalNotification(body: String, interval: TimeInterval, identifier: String) {
        let content = UNMutableNotificationContent()
        content.body = body

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}
