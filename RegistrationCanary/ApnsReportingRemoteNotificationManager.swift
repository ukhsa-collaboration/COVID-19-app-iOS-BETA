//
//  ApnsReportingRemoteNotificationManager.swift
//  RegistrationCanary
//
//  Created by NHSX on 6/10/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

let ApnsTokenReceivedNotification = NSNotification.Name("ApnsTokenReceivedNotification")

class ApnsReportingRemoteNotificationManager: ConcreteRemoteNotificationManager {
    override func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        
        super.messaging(messaging, didReceiveRegistrationToken: fcmToken)

        let apnsToken = Messaging.messaging().apnsToken?.map { String(format: "%02hhx", $0) }.joined()
        NotificationCenter.default.post(name: ApnsTokenReceivedNotification, object:apnsToken, userInfo: nil)
    }

}
