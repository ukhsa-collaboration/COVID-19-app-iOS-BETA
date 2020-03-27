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
    private let notificationManager: NotificationManager
    private let registrationService: RegistrationService
        
    init(navController: UINavigationController, diagnosisService: DiagnosisService, notificationManager: NotificationManager, registrationService: RegistrationService) {
        self.navController = navController
        self.diagnosisService = diagnosisService
        self.notificationManager = notificationManager
        self.registrationService = registrationService
    }
    
    func start() {
        navController.viewControllers = [initialViewController()]
    }
    
    func initialViewController() -> UIViewController & Storyboarded {
        switch diagnosisService.currentDiagnosis {
        case .unknown:
            return permissionsVC()

        case .infected:
            return isolateVC()

        case .notInfected:
            return okVC()

        case .potential:
            return potentialVC()
        }
    }
    
    func showViewAfterPermissions() {
        navController.pushViewController(vcAfterPermissions(), animated: true)
    }
    
    func showViewAfterRegistration() {
        navController.pushViewController(enterDiagnosisVC(), animated: true)
    }
    
    private func vcAfterPermissions() -> UIViewController {
        let registered = try! SecureRegistrationStorage.shared.get() != nil
        let currentDiagnosis = diagnosisService.currentDiagnosis
        
        switch (registered, currentDiagnosis) {
        case (false, _): return registrationVC()
        case (_, .unknown): return enterDiagnosisVC()
        case (_, .infected): return isolateVC()
        case (_, .notInfected): return okVC()
        case (_, .potential): return potentialVC()
        }
    }

    
    private func okVC() -> OkNowViewController {
        let vc = OkNowViewController.instantiate()
        vc.coordinator = self
        return vc
    }
    
    private func isolateVC() -> PleaseSelfIsolateViewController {
        let vc = PleaseSelfIsolateViewController.instantiate()
        vc.coordinator = self
        return vc
    }
    
    private func enterDiagnosisVC() -> EnterDiagnosisTableViewController {
        let vc = EnterDiagnosisTableViewController.instantiate()
        vc.coordinator = self
        return vc
    }
    
    func potentialVC() -> PotentialViewController {
        let vc = PotentialViewController.instantiate()
        vc.coordinator = self
        return vc
    }
    
    private func permissionsVC() -> PermissionsPromptViewController {
        let vc = PermissionsPromptViewController.instantiate()
        vc.coordinator = self
        return vc
    }
    
    private func registrationVC() -> RegistrationViewController {
        let vc = RegistrationViewController.instantiate()
        vc.coordinator = self
        vc.registrationService = registrationService
        vc.notificationManager = notificationManager
        return vc
    }
}
