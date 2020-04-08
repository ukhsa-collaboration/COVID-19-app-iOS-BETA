//
//  OnboardingEnvironment.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

class OnboardingEnvironment {
    // TODO: This should really happen at the model layer (e.g. auth manager, persistence).
    // Use the interactor for now since it’s already mockable to prove patterns.
    let privacyViewControllerInteractor: PrivacyViewControllerInteracting
    let persistence: Persisting
    
    init(
        persistence: Persisting = Persistence.shared,
        privacyViewControllerInteractor: PrivacyViewControllerInteracting = PrivacyViewControllerInteractor()
    ) {
        self.privacyViewControllerInteractor = privacyViewControllerInteractor
        self.persistence = persistence
    }
}
