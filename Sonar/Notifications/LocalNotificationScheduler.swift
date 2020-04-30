//
//  LocalNotificationScheduler.swift
//  Sonar
//
//  Created on 22/04/2020.
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
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: expiryDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        userNotificationCenter.add(request, withCompletionHandler: nil)
    }
    
    func removePendingDiagnosisNotification() {
        userNotificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
