//
//  BluetoothStateUserNotifier.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import CoreBluetooth

class BluetoothStateUserNotifier {
    
    let appStateReader: ApplicationStateReading
    let scheduler: LocalNotificationScheduling
    let uiQueue: TestableQueue

    init(
        appStateReader: ApplicationStateReading,
        bluetoothStateObserver: BluetoothStateObserver,
        scheduler: LocalNotificationScheduling,
        uiQueue: TestableQueue = DispatchQueue.main
    ) {
        self.appStateReader = appStateReader
        self.scheduler = scheduler
        self.uiQueue = uiQueue
        
        bluetoothStateObserver.notifyOnStateChanges { state in
            guard state == .poweredOff else { return .keepObserving }

            uiQueue.async {
                guard self.appStateReader.applicationState == .background else { return }

                self.scheduler.scheduleLocalNotification(
                    body: "To keep yourself secure, please re-enable bluetooth",
                    interval: 3,
                    identifier: "bluetooth.disabled.please"
                )
            }
            
            return .keepObserving
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
