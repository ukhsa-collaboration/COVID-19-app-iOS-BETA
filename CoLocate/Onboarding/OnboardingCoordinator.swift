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

    let persistance: Persistance
    let authorizationManager: AuthorizationManager

    init(persistance: Persistance, authorizationManager: AuthorizationManager) {
        self.persistance = persistance
        self.authorizationManager = authorizationManager
    }

    convenience init() {
        self.init(persistance: Persistance.shared, authorizationManager: AuthorizationManager())
    }

    func state(completion: @escaping (State?) -> Void) {
        let allowedDataSharing = self.persistance.allowedDataSharing
        guard allowedDataSharing else {
            completion(.initial)
            return
        }

        let allowedBluetooth = self.authorizationManager.bluetooth == .allowed
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

            let isRegistered = self.persistance.registration != nil
            guard isRegistered else {
                completion(.registration)
                return
            }

            completion(nil)
        }
    }

}
