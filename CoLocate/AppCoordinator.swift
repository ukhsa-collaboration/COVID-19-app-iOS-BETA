//
//  AppCoordinator.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class AppCoordinator {
    private let navController: UINavigationController
    private let diagnosisService: DiagnosisService
    private let secureRequestFactory: SecureRequestFactory
        
    init(navController: UINavigationController,
         diagnosisService: DiagnosisService,
         secureRequestFactory: SecureRequestFactory) {
        self.navController = navController
        self.diagnosisService = diagnosisService
        self.secureRequestFactory = secureRequestFactory
                
        diagnosisService.delegate = self
    }

    func start() {
        navController.viewControllers = [initialViewController()]
    }
    
    func initialViewController() -> UIViewController & Storyboarded {
        switch diagnosisService.currentDiagnosis {
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
        navController.pushViewController(viewControllerForDiagnosis(), animated: true)
    }

    private func viewControllerForDiagnosis() -> UIViewController {
        let currentDiagnosis = diagnosisService.currentDiagnosis
        
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

    private func okVC() -> OkNowViewController {
        let vc = OkNowViewController.instantiate()
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

extension AppCoordinator: DiagnosisServiceDelegate {
    func diagnosisService(_ diagnosisService: DiagnosisService, didRecordDiagnosis diagnosis: Diagnosis) {
        let vc: UIViewController
        
        switch diagnosis {
        case .unknown: return
        case .potential: vc = potentialVC()
        case .infected: vc = isolateVC()
        case .notInfected: vc = okVC()
        }

        navController.pushViewController(vc, animated: true)
    }
}
