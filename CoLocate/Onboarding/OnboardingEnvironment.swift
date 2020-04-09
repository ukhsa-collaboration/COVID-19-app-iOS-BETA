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
    let remoteNotificationManager: RemoteNotificationManager
    
    init(
        persistence: Persisting,
        authorizationManager: AuthorizationManaging,
        remoteNotificationManager: RemoteNotificationManager
    ) {
        self.persistence = persistence
        self.authorizationManager = authorizationManager
        self.remoteNotificationManager = remoteNotificationManager
    }
}
