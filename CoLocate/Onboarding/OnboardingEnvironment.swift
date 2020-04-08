//
//  OnboardingEnvironment.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

class OnboardingEnvironment {
    
    let persistence: Persisting
    let authorizationManager: AuthorizationManaging
    
    init(
        persistence: Persisting = Persistence.shared,
        authorizationManager: AuthorizationManaging = AuthorizationManager()
    ) {
        self.persistence = persistence
        self.authorizationManager = authorizationManager
    }
}
