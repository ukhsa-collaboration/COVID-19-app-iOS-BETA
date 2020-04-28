//
//  OnboardingEnvironment.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

class OnboardingEnvironment {
    
    let persistence: Persisting
    let authorizationManager: AuthorizationManaging
    let remoteNotificationManager: RemoteNotificationManager
    let notificationCenter: NotificationCenter
    
    init(
        persistence: Persisting,
        authorizationManager: AuthorizationManaging,
        remoteNotificationManager: RemoteNotificationManager,
        notificationCenter: NotificationCenter
    ) {
        self.persistence = persistence
        self.authorizationManager = authorizationManager
        self.remoteNotificationManager = remoteNotificationManager
        self.notificationCenter = notificationCenter
    }
}
