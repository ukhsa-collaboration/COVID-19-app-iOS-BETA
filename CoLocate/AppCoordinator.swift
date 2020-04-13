//
//  AppCoordinator.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class AppCoordinator {
    private let container: ViewControllerContainer
    private let persistence: Persisting
    private let registrationService: RegistrationService
    private let remoteNotificationDispatcher: RemoteNotificationDispatcher
    private let session: Session
    private let contactEventRepository: ContactEventRepository
        
    init(
        container: ViewControllerContainer,
        persistence: Persisting,
        registrationService: RegistrationService,
        remoteNotificationDispatcher: RemoteNotificationDispatcher,
        session: Session,
        contactEventRepository: ContactEventRepository
    ) {
        self.container = container
        self.persistence = persistence
        self.registrationService = registrationService
        self.remoteNotificationDispatcher = remoteNotificationDispatcher
        self.session = session
        self.contactEventRepository = contactEventRepository
        
        remoteNotificationDispatcher.registerHandler(forType: .potentialDisagnosis) { (userInfo, completionHandler) in
            persistence.diagnosis = .potential
            self.update()
            completionHandler(.newData)
        }
    }
    
    deinit {
        remoteNotificationDispatcher.removeHandler(forType: .potentialDisagnosis)
    }

    func update() {
        let vc = StatusViewController.instantiate()
        vc.inject(persistence: persistence, registrationService: registrationService, mainQueue: DispatchQueue.main)

        container.show(viewController: vc)
    }
}
