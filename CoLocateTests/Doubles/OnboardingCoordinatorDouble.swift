//
//  OnboardingCoordinatorDouble.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

@testable import CoLocate

class OnboardingCoordinatorDouble: OnboardingCoordinator {
    var stateCompletion: ((OnboardingCoordinator.State?) -> Void)?
    override func state(completion: @escaping (OnboardingCoordinator.State?) -> Void) {
        stateCompletion = completion
    }
}
