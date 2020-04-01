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

    var onboardingCoordinator = OnboardingCoordinator()
    var uiQueue: TestableQueue = DispatchQueue.main

    var rootViewController: UIViewController! {
        didSet { updateState() }
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

    private func handle(state: OnboardingCoordinator.State?) {
        guard let state = state else {
            performSegue(withIdentifier: "unwindFromOnboarding", sender: self)
            return
        }

        let vc: UIViewController
        switch state {
        case .initial:
            vc = StartNowViewController.instantiate()
        case .permissions:
            vc = PermissionsViewController.instantiate()
        case .registration:
            vc = RegistrationViewController.instantiate()
        }

        viewControllers = [vc]
        if presentingViewController == nil {
            rootViewController.present(self, animated: true)
        }
    }
}
