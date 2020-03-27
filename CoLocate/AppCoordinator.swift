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
    
    var navigationController: UINavigationController
    private let okVC = OkNowViewController.instantiate(storyboard: .okNow)
    private let isolateVC = PleaseSelfIsolateViewController.instantiate(storyboard: .pleaseSelfIsolate)
    private let enterDiagnosisVC = EnterDiagnosisTableViewController.instantiate(storyboard: .enterDiagnosis)
    let potentialVC = PotentialViewController.instantiate(storyboard: .potential)
    private let permissionsVC = PermissionsPromptViewController.instantiate(storyboard: .permissions)
    private let registrationVC = RegistrationViewController.instantiate(storyboard: .registration)
    
    init(diagnosisService: DiagnosisService, notificationManager: NotificationManager, registrationService: RegistrationService) {
        self.diagnosisService = diagnosisService
        self.notificationManager = notificationManager
        self.registrationService = registrationService

        navigationController = UINavigationController()
    }
    
    func start() {
        let vc = initialViewController()
        vc.coordinator = self
        navigationController = UINavigationController(rootViewController: vc)
    }
    
    func initialViewController() -> UIViewController & Storyboarded {
        switch diagnosisService.currentDiagnosis {
        case .unknown:
            return permissionsVC

        case .infected:
            return isolateVC

        case .notInfected:
            return okVC

        case .potential:
            return potentialVC
        }
    }
    
    func launchEnterDiagnosis() {
        enterDiagnosisVC.coordinator = self
        navigationController.pushViewController(enterDiagnosisVC, animated: true)
    }
    
    func launchOkNowVC() {
        okVC.coordinator = self
        navigationController.pushViewController(okVC, animated: true)
    }
    
    func goBack() {
        navigationController.popViewController(animated: true)
    }
    
    func launchPleaseIsolateVC() {
        isolateVC.coordinator = self
        navigationController.pushViewController(isolateVC, animated: true)
    }
    
    func launchPotentialVC() {
        potentialVC.coordinator = self
        navigationController.show(potentialVC, sender: self)
    }
    
    func launchRegistrationVC() {
        registrationVC.coordinator = self
        registrationVC.registrationService = registrationService
        registrationVC.notificationManager = notificationManager

        navigationController.pushViewController(registrationVC, animated: true)
    }
    
    func launchPermissionsVC() {
        permissionsVC.coordinator = self
        navigationController.pushViewController(permissionsVC, animated: true)
    }
}
