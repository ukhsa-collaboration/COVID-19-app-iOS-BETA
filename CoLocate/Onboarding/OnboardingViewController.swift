//
//  OnboardingViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class OnboardingViewController: UINavigationController, Storyboarded {
    static let storyboardName = "Onboarding"

    private var environment: OnboardingEnvironment! = nil
    private var onboardingCoordinator: OnboardingCoordinator! = nil
    var uiQueue: TestableQueue = DispatchQueue.main

    func showIn(rootViewController: RootViewController) {
        updateState()
        rootViewController.show(viewController: self)
    }

    func inject(env: OnboardingEnvironment, coordinator: OnboardingCoordinator) {
        self.environment = env
        self.onboardingCoordinator = coordinator
        self.onboardingCoordinator = coordinator
    }
    
    override func viewDidLoad() {
        if #available(iOS 13.0, *) {
            // Disallow pulling to dismiss the card modal
            isModalInPresentation = true
        } else {
            // Fallback on earlier versions
        }
        
        (viewControllers.first as! StartNowViewController).persistence = environment.persistence
    }

    func updateState() {
        onboardingCoordinator.state { [weak self] state in
            guard let self = self else { return }

            self.uiQueue.async { self.handle(state: state) }
        }
    }

    @IBAction func unwindFromPrivacy(unwindSegue: UIStoryboardSegue) {
        updateState()
    }

    @IBAction func unwindFromPermissions(unwindSegue: UIStoryboardSegue) {
        updateState()
    }

    @IBAction func unwindFromPermissionsDenied(unwindSegue: UIStoryboardSegue) {
        updateState()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
    }

    private func handle(state: OnboardingCoordinator.State) {
        let vc: UIViewController
        switch state {
        case .initial:
            vc = StartNowViewController.instantiate {
                $0.persistence = environment.persistence
            }
        case .permissions:
            vc = PermissionsViewController.instantiate {
                $0.authManager = environment.authorizationManager
                $0.remoteNotificationManager = environment.remoteNotificationManager
            }
        case .permissionsDenied:
            vc = PermissionsDeniedViewController.instantiate()
        case .registration:
            vc = RegistrationViewController.instantiate()
        }

        viewControllers = [vc]
    }
}
