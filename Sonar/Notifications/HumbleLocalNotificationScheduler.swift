//
//  HumbleLocalNotificationScheduler.swift
//  Sonar
//
//  Created by NHSX on 07/04/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

protocol LocalNotificationScheduling {
    func scheduleLocalNotification(title: String?, body: String, interval: TimeInterval, identifier: String, repeats: Bool)
}

struct HumbleLocalNotificationScheduler: LocalNotificationScheduling {
    private let userNotificationCenter: UserNotificationCenter
    
    init(userNotificationCenter: UserNotificationCenter) {
        self.userNotificationCenter = userNotificationCenter
    }

    func scheduleLocalNotification(title: String?, body: String, interval: TimeInterval, identifier: String, repeats: Bool) {
        let content = UNMutableNotificationContent()
        content.body = body
        
        if let title = title {
            content.title = title
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: repeats)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        userNotificationCenter.add(request, withCompletionHandler: nil)
    }
}
