//
//  OnboardingCoordinatorDouble.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

@testable import Sonar

class OnboardingCoordinatorDouble: OnboardingCoordinating {
    var isOnboardingRequired = true
    var stateCompletion: ((OnboardingCoordinator.State) -> Void)?
    func state(completion: @escaping (OnboardingCoordinator.State) -> Void) {
        stateCompletion = completion
    }
    func determineIsOnboardingRequired(completion: @escaping (Bool) -> Void) {
        completion(isOnboardingRequired)
    }
}
