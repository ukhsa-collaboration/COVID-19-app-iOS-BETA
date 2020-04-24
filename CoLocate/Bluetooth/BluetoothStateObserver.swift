//
//  BluetoothStateObserver.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import CoreBluetooth

class BluetoothStateObserver: BTLEListenerStateDelegate {
    
    enum Action {
        case keepObserving
        case stopObserving
    }
        
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
