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
        persistence: Persisting = Persistence.shared,
        authorizationManager: AuthorizationManaging = AuthorizationManager(),
        remoteNotificationManager: RemoteNotificationManager = ConcreteRemoteNotificationManager()
    ) {
        self.persistence = persistence
        self.authorizationManager = authorizationManager
        self.remoteNotificationManager = remoteNotificationManager
    }
}
