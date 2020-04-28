//
//  LocalNotificationScheduler.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

class LocalNotifcationScheduler {
    
    let userNotificationCenter: UserNotificationCenter
    init(userNotificationCenter: UserNotificationCenter) {
        self.userNotificationCenter = userNotificationCenter
    }
    
    func scheduleDiagnosisNotification(days: Double) {
        let identifier = "Diagnosis"
        userNotificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        let content = UNMutableNotificationContent()
        content.title = "How are you feeling today?"
        content.body = "Open the app to update your symptoms and view the latest advice."
        let components = getDateAfter(days: days, from: Date())
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        userNotificationCenter.add(request, withCompletionHandler: nil)
    }
    
    func getDateAfter(days: Double, from date: Date) -> DateComponents {
        var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date(timeInterval: days * 24 * 60 * 60, since: date))
        components.hour = 7
        components.minute = 0
        components.second = 0
        return components
    }
}
