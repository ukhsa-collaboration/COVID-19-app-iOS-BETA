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
        
    init(container: ViewControllerContainer, persistence: Persisting, registrationService: RegistrationService) {
        self.container = container
        self.persistence = persistence
        self.registrationService = registrationService
    }

    func update() {
        container.show(viewController: currentViewController())
    }
    
    private func currentViewController() -> UIViewController {
        if let diagnosis = persistence.diagnosis {
            return viewController(for: diagnosis)
        } else {
            return statusVC()
        }
    }
    
    private func viewController(for diagnosis: Diagnosis) -> UIViewController {
        switch diagnosis {
        case .infected: return isolateVC()
        case .notInfected: return statusVC()
        case .potential: return potentialVC()
        }
    }

    private func statusVC() -> StatusViewController {
        let vc = StatusViewController.instantiate()
        vc.inject(persistence: persistence, registrationService: registrationService, mainQueue: DispatchQueue.main)
        return vc
    }
    
    private func isolateVC() -> PleaseSelfIsolateViewController {
        let vc = PleaseSelfIsolateViewController.instantiate()
        return vc
    }
    
    func potentialVC() -> PotentialViewController {
        let vc = PotentialViewController.instantiate()
        return vc
    }
}
