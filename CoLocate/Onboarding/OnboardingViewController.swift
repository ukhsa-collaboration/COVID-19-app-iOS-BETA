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

    let onboardingCoordinator = OnboardingCoordinator()
    var rootViewController: UIViewController! {
        didSet { updateState() }
    }

    override func viewDidLoad() {
        if #available(iOS 13.0, *) {
            isModalInPresentation = true
        } else {
            // Fallback on earlier versions
        }
    }

    func updateState() {
        onboardingCoordinator.state { [weak self] state in
            guard let self = self else { return }

            guard let state = state else {
                self.performSegue(withIdentifier: "unwindFromOnboarding", sender: self)
                return
            }

            DispatchQueue.main.async { self.present(given: state) }
        }
    }

    @IBAction func unwindFromPrivacy(unwindSegue: UIStoryboardSegue) {
        updateState()
    }

    private func present(given state: OnboardingCoordinator.State) {
        let vc: UIViewController
        switch state {
        case .initial:
            vc = StartNowViewController.instantiate()
        case .permissions:
            vc = PermissionsViewController.instantiate()
        case .registration:
            vc = RegistrationViewController.instantiate()
        }

        self.viewControllers = [vc]
        if self.presentingViewController == nil {
            self.rootViewController.present(self, animated: true)
        }
    }
}
