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

    // TODO: find a way of making these types less “mutable”
    // Currently setting environment after `onboardingCoordinator` is used has undefined behaviour.
    // Not an issue _yet_ as `environment` is currently only ever changed in tests.
    lazy var environment = OnboardingEnvironment()
    lazy var onboardingCoordinator = OnboardingCoordinator(
        persistence: self.environment.persistence,
        authorizationManager: self.environment.authorizationManager
    )
    var uiQueue: TestableQueue = DispatchQueue.main

    func showIn(rootViewController: RootViewController) {
        updateState()
        rootViewController.show(viewController: self)
    }

    override func viewDidLoad() {
        if #available(iOS 13.0, *) {
            // Disallow pulling to dismiss the card modal
            isModalInPresentation = true
        } else {
            // Fallback on earlier versions
        }
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

    private func handle(state: OnboardingCoordinator.State) {
        let vc: UIViewController
        switch state {
        case .initial:
            vc = StartNowViewController.instantiate {
                $0.environment = environment
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
