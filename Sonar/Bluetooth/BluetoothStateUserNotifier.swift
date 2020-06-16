//
//  BluetoothStateUserNotifier.swift
//  Sonar
//
//  Created by NHSX on 07/04/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class BluetoothStateUserNotifier {
    
    let appStateReader: ApplicationStateReading
    let scheduler: LocalNotificationScheduling
    let uiQueue: TestableQueue

    init(
        appStateReader: ApplicationStateReading,
        bluetoothStateObserver: BluetoothStateObserving,
        scheduler: LocalNotificationScheduling,
        uiQueue: TestableQueue = DispatchQueue.main
    ) {
        self.appStateReader = appStateReader
        self.scheduler = scheduler
        self.uiQueue = uiQueue
        
        bluetoothStateObserver.observe { state in
            guard state == .poweredOff else { return .keepObserving }

            uiQueue.async {
                guard self.appStateReader.applicationState == .background else { return }

                self.scheduler.scheduleLocalNotification(
                    title: "Please turn Bluetooth on",
                    body: "This app can only protect you and others if Bluetooth is on all the time.",
                    interval: 3,
                    identifier: "bluetooth.disabled.please",
                    repeats: false
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
