//
//  OnboardingCoordinator.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import CoreBluetooth
import Foundation
import Logging

class OnboardingCoordinator: BluetoothStateObserverDelegate {
    private typealias BluetoothCompletion = (State?) -> Void

    enum State: Equatable {
        case initial, partialPostcode, permissions, bluetoothDenied, bluetoothOff, notificationsDenied, done
    }

    private let persistence: Persisting
    private let authorizationManager: AuthorizationManaging
    private var hasShownInitialScreen = false
    private var bluetoothStateObserver: BluetoothStateObserver
    private var pendingBluetoothCompletions: [BluetoothCompletion] = []

    init(
        persistence: Persisting,
        authorizationManager: AuthorizationManaging,
        bluetoothStateObserver: BluetoothStateObserver
    ) {
        self.persistence = persistence
        self.authorizationManager = authorizationManager
        self.bluetoothStateObserver = bluetoothStateObserver
        self.bluetoothStateObserver.delegate = self
    }

    func state(completion: @escaping (State) -> Void) {
        guard hasShownInitialScreen || persistence.partialPostcode != nil else {
            hasShownInitialScreen = true
            completion(.initial)
            return
        }

        guard persistence.partialPostcode != nil else {
            completion(.partialPostcode)
            return
        }
        
        switch self.authorizationManager.bluetooth {
        case .notDetermined:
            completion(.permissions)
            return
        case .denied:
            completion(.bluetoothDenied)
            return
        case .allowed:
            break
        }
        
        maybeStateFromBluetooth { [weak self] state in
            if state != nil {
                completion(state!)
            } else {
                guard let self = self else { return }

                self.authorizationManager.notifications { notificationStatus in
                    switch (notificationStatus) {
                    case .notDetermined:
                        completion(.permissions)
                    case .denied:
                        completion(.notificationsDenied)
                    case .allowed:
                        completion(.done)
                    }
                }
            }
        }
    }

    private func maybeStateFromBluetooth(completion: @escaping BluetoothCompletion) {
        switch self.authorizationManager.bluetooth {
        case .notDetermined:
            completion(.permissions)
        case .denied:
            completion(.bluetoothDenied)
        case .allowed:
            switch self.bluetoothStateObserver.state() {
            case .poweredOff:
                completion(.bluetoothOff)
            case .unknown:
                // bluetoothStateObserver(didChangeState) should get called soon with the new state.
                // Queue up the completion to be called when it comes through.
                pendingBluetoothCompletions.append(completion)
            default:
                completion(nil)
            }
        }
    }
    
    private func callPendingBluetoothCompletions(state: State?) {
        while let c = pendingBluetoothCompletions.popLast() {
            c(state)
        }
    }
    
    func bluetoothStateObserver(_ sender: BluetoothStateObserver, didChangeState state: CBManagerState) {
        switch state {
        case .poweredOff:
            callPendingBluetoothCompletions(state: .bluetoothOff)
        case .unknown:
            // Keep waiting
            logger.info("CBManagerState changed to unknown")
            break;
        default:
            callPendingBluetoothCompletions(state: nil)
        }
    }

}


private let logger = Logger(label: "OnboardingCoordinator")
