//
//  RootViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

protocol ViewControllerContainer {
    func show(viewController: UIViewController)
}

class RootViewController: UIViewController {

    private var persistence: Persisting! = nil
    private var authorizationManager: AuthorizationManaging! = nil
    private var remoteNotificationManager: RemoteNotificationManager! = nil
    private var notificationCenter: NotificationCenter! = nil
    private var registrationService: RegistrationService! = nil

    func inject(
        persistence: Persisting,
        authorizationManager: AuthorizationManaging,
        remoteNotificationManager: RemoteNotificationManager,
        notificationCenter: NotificationCenter,
        registrationService: RegistrationService
    ) {
        self.persistence = persistence
        self.authorizationManager = authorizationManager
        self.remoteNotificationManager = remoteNotificationManager
        self.notificationCenter = notificationCenter
        self.registrationService = registrationService
    }
    
    override func viewDidLoad() {
        showFirstView()
    }
    
    // MARK: - Routing
    func showFirstView() {
        if persistence.registration != nil {
            startMainApp()
        } else {
            let onboardingViewController = OnboardingViewController.instantiate()
            let env = OnboardingEnvironment(persistence: persistence, authorizationManager: authorizationManager, remoteNotificationManager: remoteNotificationManager, notificationCenter: NotificationCenter.default)
            let coordinator = OnboardingCoordinator(persistence: persistence, authorizationManager: authorizationManager)
            
            onboardingViewController.inject(env: env, coordinator: coordinator, uiQueue: DispatchQueue.main) {
                self.startMainApp()
            }
            
            onboardingViewController.showIn(container: self)
        }
    }
    
    private func startMainApp() {
        let appCoordinator = AppCoordinator(
            container: self,
            persistence: persistence,
            registrationService: registrationService,
            remoteNotificationDispatcher: remoteNotificationManager.dispatcher
        )
        appCoordinator.update()
    }
    
    // MARK: - Debug view controller management
    
    #if DEBUG || INTERNAL
    var previouslyPresentedViewController: UIViewController?

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if let vc = presentedViewController {
            previouslyPresentedViewController = vc
            dismiss(animated: true)
        }

        if motion == UIEvent.EventSubtype.motionShake {
            showDebugView()
        }
    }

    @IBAction func unwindFromDebugViewController(unwindSegue: UIStoryboardSegue) {
        dismiss(animated: true)

        if let vc = previouslyPresentedViewController {
            present(vc, animated: true)
        }
    }

    private func showDebugView() {
        let storyboard = UIStoryboard(name: "Debug", bundle: Bundle(for: Self.self))
        guard let debugVC = storyboard.instantiateInitialViewController() else { return }
        present(debugVC, animated: true)
    }
    #endif
}

 
extension RootViewController: ViewControllerContainer {
    func show(viewController newChild: UIViewController) {
        children.first?.willMove(toParent: nil)
        children.first?.viewIfLoaded?.removeFromSuperview()
        children.first?.removeFromParent()
        addChild(newChild)
        newChild.view.frame = view.bounds
        view.addSubview(newChild.view)
        newChild.didMove(toParent: self)
    }
}
