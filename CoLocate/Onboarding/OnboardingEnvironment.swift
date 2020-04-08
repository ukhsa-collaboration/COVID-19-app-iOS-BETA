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
    
    init(
        persistence: Persisting = Persistence.shared
    ) {
        self.persistence = persistence
    }
}
