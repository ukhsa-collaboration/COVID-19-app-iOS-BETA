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

class OnboardingCoordinator {
    private typealias BluetoothCompletion = (State?) -> Void

    enum State: Equatable {
        case initial, partialPostcode, permissions, bluetoothDenied, bluetoothOff, notificationsDenied, done
    }

    private let persistence: Persisting
    private let authorizationManager: AuthorizationManaging
    private var hasShownInitialScreen = false
    private var bluetoothNursery: BluetoothNursery

    init(
        persistence: Persisting,
        authorizationManager: AuthorizationManaging,
        bluetoothNursery: BluetoothNursery
    ) {
        self.persistence = persistence
        self.authorizationManager = authorizationManager
        self.bluetoothNursery = bluetoothNursery
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
            let btStateObserver = self.bluetoothNursery.stateObserver

            btStateObserver.observeUntilKnown { btState in
                if btState == .poweredOff {
                    completion(.bluetoothOff)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
}


private let logger = Logger(label: "OnboardingCoordinator")
