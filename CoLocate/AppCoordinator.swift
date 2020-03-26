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
    
    var navigationController: UINavigationController
    private let okVC = OkNowViewController.instantiate(storyboard: .okNow)
    private let isolateVC = PleaseSelfIsolateViewController.instantiate(storyboard: .pleaseSelfIsolate)
    private let enterDiagnosisVC = EnterDiagnosisTableViewController.instantiate(storyboard: .enterDiagnosis)
    let potentialVC = PotentialViewController.instantiate(storyboard: .potential)
    private let permissionsVC = PermissionsPromptViewController.instantiate(storyboard: .permissions)
    private let registrationVC = RegistrationViewController.instantiate(storyboard: .registration)
    
    init(diagnosisService: DiagnosisService) {
        self.diagnosisService = diagnosisService
        navigationController = UINavigationController()
    }
    
    func start() {
        var rootViewController: Storyboarded?
            switch diagnosisService.currentDiagnosis {
            
            case .unknown:
                rootViewController = permissionsVC

            case .infected:
                rootViewController = isolateVC

            case .notInfected:
                rootViewController = okVC

            case .potential:
                rootViewController = potentialVC
            }
        if let vc = rootViewController as? UIViewController & Storyboarded {
            vc.coordinator = self
            navigationController = UINavigationController(rootViewController: vc)
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
        navigationController.pushViewController(registrationVC, animated: true)
    }
    
    func launchPermissionsVC() {
        permissionsVC.coordinator = self
        navigationController.pushViewController(permissionsVC, animated: true)
    }
}
