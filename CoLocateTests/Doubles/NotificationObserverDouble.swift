//
//  NotificationObserverDouble.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

class NotificationObserverDouble {
    var lastNotification: Notification?
    private let notificationCenter: NotificationCenter
    
    init(notificationCenter: NotificationCenter, notificationName: NSNotification.Name) {
        self.notificationCenter = notificationCenter
        notificationCenter.addObserver(self, selector: #selector(didReceive(notification:)), name: notificationName, object: nil)
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
    
    @objc func didReceive(notification: Notification) {
        lastNotification = notification
    }
}
