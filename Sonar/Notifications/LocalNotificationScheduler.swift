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
        content.title = "NHS COVID-19"
        content.body = "How are you feeling today?\n\nPlease open the app to update your symptoms and view your latest advice. Your help saves lives."
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: expiryDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        userNotificationCenter.add(request, withCompletionHandler: nil)
    }
    
    func removePendingDiagnosisNotification() {
        userNotificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
