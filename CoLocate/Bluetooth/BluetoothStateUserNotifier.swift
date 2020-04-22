//
//  BluetoothStateObserver.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import CoreBluetooth

struct BluetoothStateUserNotifier: BTLEListenerStateDelegate {
    
    let appStateReader: ApplicationStateReading
    let scheduler: LocalNotificationScheduling
    let uiQueue: TestableQueue

    init(appStateReader: ApplicationStateReading, scheduler: LocalNotificationScheduling, uiQueue: TestableQueue = DispatchQueue.main) {
        self.appStateReader = appStateReader
        self.scheduler = scheduler
        self.uiQueue = uiQueue
    }

    func btleListener(_ listener: BTLEListener, didUpdateState state: CBManagerState) {
        guard state == .poweredOff else { return }

        uiQueue.async {
            guard self.appStateReader.applicationState == .background else { return }
            
            self.scheduler.scheduleLocalNotification(
                body: "To keep yourself secure, please re-enable bluetooth",
                interval: 3,
                identifier: "bluetooth.disabled.please"
            )
        }
    }
}

// MARK: - Testable

protocol ApplicationStateReading {
    var applicationState: UIApplication.State { get }
}

extension UIApplication: ApplicationStateReading { }

protocol LocalNotificationScheduling {
    func scheduleLocalNotification(body: String, interval: TimeInterval, identifier: String)
}
