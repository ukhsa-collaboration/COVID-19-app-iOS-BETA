//
//  SetupChecker.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import CoreBluetooth

enum SetupProblem {
    case bluetoothOff
    case bluetoothPermissions
    case notificationPermissions
}

class SetupChecker {
    private let authorizationManager: AuthorizationManaging
    private let bluetoothNursery: BluetoothNursery
    
    
    init(authorizationManager: AuthorizationManaging, bluetoothNursery: BluetoothNursery) {
        self.authorizationManager = authorizationManager
        self.bluetoothNursery = bluetoothNursery
    }
    
    func check(_ callback: @escaping (SetupProblem?) -> Void) {
        // We can only show one error at a time. We show them in this order, if possible:
        // 1. Bluetooth off
        // 2. No Bluetooth permissions
        // 3. No notification permsisions
        var notificationStatus: NotificationAuthorizationStatus?
        var btStatus: CBManagerState?
        
        func maybeFinish() {
            guard let notificationStatus = notificationStatus, let btStatus = btStatus else { return }
            
            if btStatus == .poweredOff {
                callback(.bluetoothOff)
            } else if authorizationManager.bluetooth == .denied {
                callback(.bluetoothPermissions)
            } else if notificationStatus == .denied {
                callback(.notificationPermissions)
            } else {
                callback(nil)
            }
        }
        
        self.bluetoothNursery.stateObserver.observeUntilKnown { status in
            btStatus = status
            maybeFinish()
        }

        authorizationManager.notifications { s in
            notificationStatus = s
            maybeFinish()
        }
    }
}
