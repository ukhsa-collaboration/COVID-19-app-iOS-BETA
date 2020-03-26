//
//  AppCoordinator.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

//protocol Coordinator {
//    var navigationController: UINavigationController { get set }
//    func start()
//}

class AppCoordinator { //Coordinator {
    
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
                rootViewController = registrationVC
                
                if let vc = (rootViewController as? RegistrationViewController) {
                    vc.inject()
                }

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
        navigationController.pushViewController(okVC, animated: true)
    }
    
    func launchPleaseIsolateVC() {
        navigationController.pushViewController(isolateVC, animated: true)
    }
    
    func launchPotentialVC() {
        navigationController.show(potentialVC, sender: self)
    }
    
    func launchRegistrationVC() {
        navigationController.pushViewController(registrationVC, animated: true)
    }
    
    func launchPermissionsVC() {
        navigationController.pushViewController(permissionsVC, animated: true)
    }
}
