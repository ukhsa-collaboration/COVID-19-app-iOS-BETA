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

    var state: State? {
        let allowedDataSharing = persistance.allowedDataSharing
        let allowedBluetooth = authorizationManager.bluetooth == .allowed
        let allowedNotifications = authorizationManager.notifications == .allowed
        let isRegistered = persistance.registration != nil

        switch (allowedDataSharing, allowedBluetooth, allowedNotifications, isRegistered) {
        case (false, _, _, _): return .initial
        case (true, false, _, _), (true, _, false, _): return .permissions
        case (true, true, true, false): return .registration
        case (true, true, true, true): return nil
        }
    }

    init(persistance: Persistance, authorizationManager: AuthorizationManager) {
        self.persistance = persistance
        self.authorizationManager = authorizationManager
    }

    convenience init() {
        self.init(persistance: Persistance.shared, authorizationManager: AuthorizationManager())
    }

}

