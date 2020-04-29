//
//  LocalNotificationScheduler.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

protocol Scheduler {
    func scheduleDiagnosisNotification(expiryDate: Date)
}

class LocalNotifcationScheduler: Scheduler {
    let identifier = "Diagnosis"
    let userNotificationCenter: UserNotificationCenter
    init(userNotificationCenter: UserNotificationCenter) {
        self.userNotificationCenter = userNotificationCenter
    }
    
    func scheduleDiagnosisNotification(expiryDate: Date) {
        removePendingDiagnosisNotification()
        
        let content = UNMutableNotificationContent()
        content.title = "How are you feeling today?"
        content.body = "Open the app to update your symptoms and view the latest advice."
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents(in: .current, from: expiryDate), repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        userNotificationCenter.add(request, withCompletionHandler: nil)
    }
    
    func removePendingDiagnosisNotification() {
        userNotificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
