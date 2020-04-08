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
        case initial, permissions, permissionsDenied, registration
    }

    private let persistence: Persisting
    private let authorizationManager: AuthorizationManaging

    init(persistence: Persisting, authorizationManager: AuthorizationManaging) {
        self.persistence = persistence
        self.authorizationManager = authorizationManager
    }

    convenience init() {
        self.init(persistence: Persistence.shared, authorizationManager: AuthorizationManager())
    }

    func state(completion: @escaping (State) -> Void) {
        let allowedDataSharing = persistence.allowedDataSharing
        guard allowedDataSharing else {
            completion(.initial)
            return
        }

        authorizationManager.notifications { [weak self] notificationStatus in
            guard let self = self else { return }

            switch (self.authorizationManager.bluetooth, notificationStatus) {
            case (.notDetermined, _), (_, .notDetermined):
                completion(.permissions)
                return
            case (.denied, _), (_, .denied):
                completion(.permissionsDenied)
                return
            case (.allowed, .allowed):
                completion(.registration)
            }
        }
    }

}
