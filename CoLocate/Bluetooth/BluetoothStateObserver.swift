//
//  BluetoothStateObserver.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import CoreBluetooth

protocol BluetoothStateObserving: BTLEListenerStateDelegate {
    func observe(_ callback: @escaping (CBManagerState) -> Action)
    func observeUntilKnown(_ callback: @escaping (CBManagerState) -> Void)
}

enum Action {
    case keepObserving
    case stopObserving
}

class BluetoothStateObserver: BluetoothStateObserving {
    
    private var callbacks: [(CBManagerState) -> Action]
    private var lastKnownState: CBManagerState
    
    init(initialState: CBManagerState) {
        callbacks = []
        lastKnownState = initialState
    }
        
    // Callback will be called immediately with the last known state and every time the state changes in the future.
    func observe(_ callback: @escaping (CBManagerState) -> Action) {
        if callback(lastKnownState) == .keepObserving {
            callbacks.append(callback)
        }
    }
    
    func observeUntilKnown(_ callback: @escaping (CBManagerState) -> Void) {
        observe { state in
            if state == .unknown {
                return .keepObserving
            } else {
                callback(state)
                return .stopObserving
            }
        }
    }

    // MARK: - BTLEListenerStateDelegate

    func btleListener(_ listener: BTLEListener, didUpdateState state: CBManagerState) {
        lastKnownState = state
        
        var callbacksToKeep: [(CBManagerState) -> Action] = []
        
        for entry in callbacks {
            if entry(lastKnownState) == .keepObserving {
                callbacksToKeep.append(entry)
            }
        }

        callbacks = callbacksToKeep
    }

}
