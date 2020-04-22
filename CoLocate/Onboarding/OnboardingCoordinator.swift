//
//  OnboardingCoordinator.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import CoreBluetooth
import Foundation

class OnboardingCoordinator {

    enum State: Equatable {
        case initial, partialPostcode, permissions, bluetoothDenied, notificationsDenied, done
    }

    private let persistence: Persisting
    private let authorizationManager: AuthorizationManaging
    private var hasShownInitialScreen = false

    init(persistence: Persisting, authorizationManager: AuthorizationManaging) {
        self.persistence = persistence
        self.authorizationManager = authorizationManager
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

        authorizationManager.notifications { [weak self] notificationStatus in
            guard let self = self else { return }

            switch (self.authorizationManager.bluetooth, notificationStatus) {
            case (.notDetermined, _), (_, .notDetermined):
                completion(.permissions)
            case (.denied, _):
                completion(.bluetoothDenied)
            case (_, .denied):
                completion(.notificationsDenied)
            case (.allowed, .allowed):
                completion(.done)
            }
        }
    }

}
