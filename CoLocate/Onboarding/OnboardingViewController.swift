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
    private var completionHandler: (() -> Void)! = nil
    private var uiQueue: TestableQueue! = nil

    func showIn(container: ViewControllerContainer) {
        updateState()
        container.show(viewController: self)
    }

    func inject(env: OnboardingEnvironment, coordinator: OnboardingCoordinator, uiQueue: TestableQueue, completionHandler: @escaping () -> Void) {
        self.environment = env
        self.onboardingCoordinator = coordinator
        self.completionHandler = completionHandler
        self.uiQueue = uiQueue
    }
    
    override func viewDidLoad() {
        if #available(iOS 13.0, *) {
            // Disallow pulling to dismiss the card modal
            isModalInPresentation = true
        } else {
            // Fallback on earlier versions
        }
        
        (viewControllers.first as! StartNowViewController).inject(persistence: environment.persistence,
                                                                  notificationCenter: environment.notificationCenter,
                                                                  continueHandler: updateState)
    }

    func updateState() {
        onboardingCoordinator.state { [weak self] state in
            guard let self = self else { return }

            self.uiQueue.async { self.handle(state: state) }
        }
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
            vc = StartNowViewController.instantiate() {
                $0.inject(persistence: environment.persistence, notificationCenter: environment.notificationCenter, continueHandler: updateState)
            }
            
        case .partialPostcode:
            vc = PostcodeViewController.instantiate() {
                $0.inject(persistence: environment.persistence, notificationCenter: environment.notificationCenter, continueHandler: updateState)
            }
            
        case .permissions:
            vc = PermissionsViewController.instantiate() {
                $0.inject(authManager: environment.authorizationManager, remoteNotificationManager: environment.remoteNotificationManager, uiQueue: uiQueue, continueHandler: updateState)
            }
            
        case .bluetoothDenied:
            vc = BluetoothPermissionDeniedViewController.instantiate() {
                $0.inject(notificationCenter: environment.notificationCenter, uiQueue: uiQueue, continueHandler: updateState)
           }
            
        case .notificationsDenied:
             vc = NotificationPermissionDeniedViewController.instantiate() {
                 $0.inject(notificationCenter: environment.notificationCenter, uiQueue: uiQueue, continueHandler: updateState)
            }

        case .done:
            completionHandler()
            return
        }

        viewControllers = [vc]
    }
}
