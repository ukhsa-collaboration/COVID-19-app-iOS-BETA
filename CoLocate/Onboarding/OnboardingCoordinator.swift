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
        case initial, permissions, registration
    }

    let persistence: Persistence
    let authorizationManager: AuthorizationManager

    init(persistence: Persistence, authorizationManager: AuthorizationManager) {
        self.persistence = persistence
        self.authorizationManager = authorizationManager
    }

    convenience init() {
        self.init(persistence: Persistence.shared, authorizationManager: AuthorizationManager())
    }

    func state(completion: @escaping (State?) -> Void) {
        let allowedDataSharing = persistence.allowedDataSharing
        guard allowedDataSharing else {
            completion(.initial)
            return
        }

        let allowedBluetooth = authorizationManager.bluetooth == .allowed
        guard allowedBluetooth else {
            completion(.permissions)
            return
        }

        authorizationManager.notifications { [weak self] notificationStatus in
            guard let self = self else { return }

            let allowedNotifications = notificationStatus == .allowed
            guard allowedNotifications else {
                completion(.permissions)
                return
            }

            let isRegistered = self.persistence.registration != nil
            guard isRegistered else {
                completion(.registration)
                return
            }

            completion(nil)
        }
    }

}
