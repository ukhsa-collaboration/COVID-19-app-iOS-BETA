//
//  OnboardingCoordinatorDouble.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

@testable import Sonar

class OnboardingCoordinatorDouble: OnboardingCoordinator {
    convenience init() {
        self.init(persistence: PersistenceDouble(), authorizationManager: AuthorizationManager(), bluetoothNursery: BluetoothNurseryDouble())
    }
    var stateCompletion: ((OnboardingCoordinator.State) -> Void)?
    override func state(completion: @escaping (OnboardingCoordinator.State) -> Void) {
        stateCompletion = completion
    }
}
