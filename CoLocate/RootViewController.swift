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
    private var session: Session! = nil
    private var contactEventRepository: PersistingContactEventRepository! = nil
    private var statusViewController: StatusViewController!

    func inject(
        persistence: Persisting,
        authorizationManager: AuthorizationManaging,
        remoteNotificationManager: RemoteNotificationManager,
        notificationCenter: NotificationCenter,
        registrationService: RegistrationService,
        session: Session,
        contactEventRepository: PersistingContactEventRepository

    ) {
        self.persistence = persistence
        self.authorizationManager = authorizationManager
        self.remoteNotificationManager = remoteNotificationManager
        self.notificationCenter = notificationCenter
        self.registrationService = registrationService
        self.session = session
        self.contactEventRepository = contactEventRepository

        statusViewController = StatusViewController.instantiate()
        statusViewController.inject(
            persistence: persistence,
            registrationService: registrationService,
            mainQueue: DispatchQueue.main
        )

        remoteNotificationManager.dispatcher.registerHandler(forType: .potentialDisagnosis) { (userInfo, completionHandler) in
            persistence.diagnosis = .potential
            self.statusViewController.diagnosis = .potential
            completionHandler(.newData)
        }
    }

    deinit {
        remoteNotificationManager.dispatcher.removeHandler(forType: .potentialDisagnosis)
    }
    
    override func viewDidLoad() {
        showFirstView()
    }
    
    // MARK: - Routing
    func showFirstView() {
        if persistence.registration != nil {
            show(viewController: statusViewController)
        } else {
            let onboardingViewController = OnboardingViewController.instantiate()
            let env = OnboardingEnvironment(persistence: persistence, authorizationManager: authorizationManager, remoteNotificationManager: remoteNotificationManager, notificationCenter: NotificationCenter.default)
            let coordinator = OnboardingCoordinator(persistence: persistence, authorizationManager: authorizationManager)
            
            onboardingViewController.inject(env: env, coordinator: coordinator, uiQueue: DispatchQueue.main) {
                self.show(viewController: self.statusViewController)
            }
            
            onboardingViewController.showIn(container: self)
        }
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
