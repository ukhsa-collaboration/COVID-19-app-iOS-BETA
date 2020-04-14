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
    private var contactEventRepository: ContactEventRepository! = nil
    private var statusViewController: StatusViewController!
    private var session: Session! = nil
    private var uiQueue: TestableQueue! = nil

    func inject(
        persistence: Persisting,
        authorizationManager: AuthorizationManaging,
        remoteNotificationManager: RemoteNotificationManager,
        notificationCenter: NotificationCenter,
        registrationService: RegistrationService,
        contactEventRepository: ContactEventRepository,
        session: Session,
        uiQueue: TestableQueue
    ) {
        self.persistence = persistence
        self.authorizationManager = authorizationManager
        self.remoteNotificationManager = remoteNotificationManager
        self.notificationCenter = notificationCenter
        self.registrationService = registrationService
        self.contactEventRepository = contactEventRepository
        self.session = session
        self.uiQueue = uiQueue

        statusViewController = StatusViewController.instantiate()
        statusViewController.inject(
            persistence: persistence,
            registrationService: registrationService,
            mainQueue: uiQueue,
            contactEventRepo: contactEventRepository,
            session: session
        )
        
        notificationCenter.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)

        remoteNotificationManager.dispatcher.registerHandler(forType: .potentialDisagnosis) { (userInfo, completionHandler) in
            persistence.diagnosis = .potential
            self.statusViewController.diagnosis = .potential
            completionHandler(.newData)
        }
    }

    deinit {
        notificationCenter.removeObserver(self)
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
            
            onboardingViewController.inject(env: env, coordinator: coordinator, uiQueue: self.uiQueue) {
                self.show(viewController: self.statusViewController)
            }
            
            onboardingViewController.showIn(container: self)
        }
    }
    
    @objc func applicationDidBecomeActive(_ notification: NSNotification) {
        guard self.persistence.registration != nil else { return }

        authorizationManager.notifications { [weak self] notificationStatus in
            guard let self = self else { return }

            self.uiQueue.sync {
                switch (self.authorizationManager.bluetooth, notificationStatus) {
                case (.denied, _), (_, .denied):
                    let permissionsDeniedViewController = PermissionsDeniedViewController.instantiate()
                self.present(permissionsDeniedViewController, animated: true)
                default:
                    guard self.presentedViewController as? PermissionsDeniedViewController != nil else {
                        return
                    }

                    self.dismiss(animated: true)
                }
            }
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
