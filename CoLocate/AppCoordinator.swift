//
//  AppCoordinator.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class AppCoordinator {
    private let rootViewController: RootViewController
    private let persistence: Persisting
        
    init(rootViewController: RootViewController, persistence: Persisting) {
        self.rootViewController = rootViewController
        self.persistence = persistence
    }

    func start() {
        let vc = initialViewController()
        rootViewController.show(viewController: vc)
    }
    
    func initialViewController() -> UIViewController & Storyboarded {
        switch persistence.diagnosis {
        case .unknown:
            return statusVC()

        case .infected:
            return isolateVC()

        case .notInfected:
            return statusVC()

        case .potential:
            return potentialVC()
        }
    }
    
    func showAppropriateViewController() {
        rootViewController.show(viewController: viewControllerForDiagnosis())
    }

    private func viewControllerForDiagnosis() -> UIViewController {
        let currentDiagnosis = persistence.diagnosis
        
        switch currentDiagnosis {
        case .unknown: return enterDiagnosisVC()
        case .infected: return isolateVC()
        case .notInfected: return statusVC()
        case .potential: return potentialVC()
        }
    }

    private func enterDiagnosisVC() -> EnterDiagnosisTableViewController {
        let vc = EnterDiagnosisTableViewController.instantiate()
        return vc
    }

    private func statusVC() -> StatusViewController {
        return StatusViewController.instantiate()
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
