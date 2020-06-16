//
//  BluetoothStateObserver.swift
//  Sonar
//
//  Created by NHSX on 4/23/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

protocol BluetoothStateObserving: ListenerStateDelegate {
    func observe(_ callback: @escaping (SonarBTManagerState) -> Action)
    func observeUntilKnown(_ callback: @escaping (SonarBTManagerState) -> Void)
}

enum Action {
    case keepObserving
    case stopObserving
}

class BluetoothStateObserver: BluetoothStateObserving {
    
    private var callbacks: [(SonarBTManagerState) -> Action]
    private var lastKnownState: SonarBTManagerState
    
    init(initialState: SonarBTManagerState) {
        callbacks = []
        lastKnownState = initialState
    }
        
    // Callback will be called immediately with the last known state
    // and every time the state changes in the future, until it returns
    // .stopObserving
    func observe(_ callback: @escaping (SonarBTManagerState) -> Action) {
        if callback(lastKnownState) == .keepObserving {
            callbacks.append(callback)
        }
    }
    
    // Callback will be called once the next time the state transitions to
    // something other than .unknown. Use this to find out the current state
    // once.
    func observeUntilKnown(_ callback: @escaping (SonarBTManagerState) -> Void) {
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

    func listener(_ listener: Listener, didUpdateState state: SonarBTManagerState) {
        lastKnownState = state
        
        var callbacksToKeep: [(SonarBTManagerState) -> Action] = []
        
        for entry in callbacks {
            if entry(lastKnownState) == .keepObserving {
                callbacksToKeep.append(entry)
            }
        }

        callbacks = callbacksToKeep
    }

}
