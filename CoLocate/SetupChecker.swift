//
//  SetupChecker.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

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
        authorizationManager.notifications { notificationStatus in
            if notificationStatus == .denied {
                callback(.notificationPermissions)
            } else if self.authorizationManager.bluetooth == .denied {
                callback(.bluetoothPermissions)
            } else if let btObserver = self.bluetoothNursery.stateObserver {
                btObserver.observeUntilKnown { btState in
                    if btState == .poweredOff {
                        callback(.bluetoothOff)
                    } else {
                        callback(nil)
                    }
                }
            } else {
                callback(nil)
            }
        }
    }
}
