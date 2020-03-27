//
//  AppCoordinator.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class AppCoordinator {
    
    private let diagnosisService: DiagnosisService
    private let notificationManager: NotificationManager
    private let registrationService: RegistrationService
    
    var navigationController: RootViewController
    
    init(diagnosisService: DiagnosisService, notificationManager: NotificationManager, registrationService: RegistrationService) {
        self.diagnosisService = diagnosisService
        self.notificationManager = notificationManager
        self.registrationService = registrationService

        navigationController = RootViewController()
    }
    
    func start() {
        navigationController.viewControllers = [initialViewController()]
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
    
    func launchEnterDiagnosis() {
        navigationController.pushViewController(enterDiagnosisVC(), animated: true)
    }
    
    func launchOkNowVC() {
        navigationController.pushViewController(okVC(), animated: true)
    }
    
    func goBack() {
        navigationController.popViewController(animated: true)
    }
    
    func launchPleaseIsolateVC() {
        navigationController.pushViewController(isolateVC(), animated: true)
    }
    
    func launchPotentialVC() {
        navigationController.show(potentialVC(), sender: self)
    }
    
    func showViewAfterPermissions() {
        if try! SecureRegistrationStorage.shared.get() == nil {
            launchRegistrationVC()
        } else {
            switch diagnosisService.currentDiagnosis {
            case .unknown:
                launchEnterDiagnosis()

            case .infected:
                launchPleaseIsolateVC()

            case .notInfected:
                launchOkNowVC()

            case .potential:
                launchPotentialVC()
            }
        }
    }
    
    func launchPermissionsVC() {
        navigationController.pushViewController(permissionsVC(), animated: true)
    }
    
    private func launchRegistrationVC() {
        navigationController.pushViewController(registrationVC(), animated: true)
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
