//
//  HumbleLocalNotificationScheduler.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct HumbleLocalNotificationScheduler: LocalNotificationScheduling {
    private let userNotificationCenter: UserNotificationCenter
    
    init(userNotificationCenter: UserNotificationCenter) {
        self.userNotificationCenter = userNotificationCenter
    }
    

    func scheduleLocalNotification(body: String, interval: TimeInterval, identifier: String) {
        let content = UNMutableNotificationContent()
        content.body = body

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        userNotificationCenter.add(request, withCompletionHandler: nil)
    }
}
