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
    private let persistence: Persistence
    private let secureRequestFactory: SecureRequestFactory
        
    init(rootViewController: RootViewController,
         persistence: Persistence,
         secureRequestFactory: SecureRequestFactory) {
        self.rootViewController = rootViewController
        self.persistence = persistence
        self.secureRequestFactory = secureRequestFactory
    }

    func start() {
        rootViewController.show(viewController: initialViewController())
    }
    
    func initialViewController() -> UIViewController & Storyboarded {
        switch persistence.diagnosis {
        case .unknown:
            return okVC()

        case .infected:
            return isolateVC()

        case .notInfected:
            return okVC()

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
        case .notInfected: return okVC()
        case .potential: return potentialVC()
        }
    }

    private func enterDiagnosisVC() -> EnterDiagnosisTableViewController {
        let vc = EnterDiagnosisTableViewController.instantiate()
        return vc
    }

    private func okVC() -> OkViewController {
        let vc = OkViewController.instantiate()
        return vc
    }
    
    private func isolateVC() -> PleaseSelfIsolateViewController {
        let vc = PleaseSelfIsolateViewController.instantiate()
        vc.requestFactory = secureRequestFactory
        return vc
    }
    
    func potentialVC() -> PotentialViewController {
        let vc = PotentialViewController.instantiate()
        return vc
    }
}
