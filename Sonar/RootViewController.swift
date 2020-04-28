//
//  RootViewController.swift
//  Sonar
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
    private var bluetoothNursery: BluetoothNursery!
    private var session: Session!
    private var contactEventsUploader: ContactEventsUploader!
    private var uiQueue: TestableQueue! = nil
    private weak var presentedSetupErorrViewController: UIViewController? = nil

    private var statusViewController: StatusViewController!

    func inject(
        persistence: Persisting,
        authorizationManager: AuthorizationManaging,
        remoteNotificationManager: RemoteNotificationManager,
        notificationCenter: NotificationCenter,
        registrationService: RegistrationService,
        bluetoothNursery: BluetoothNursery,
        session: Session,
        contactEventsUploader: ContactEventsUploader,
        linkingIdManager: LinkingIdManager,
        statusProvider: StatusProvider,
        uiQueue: TestableQueue
    ) {
        self.persistence = persistence
        self.authorizationManager = authorizationManager
        self.remoteNotificationManager = remoteNotificationManager
        self.notificationCenter = notificationCenter
        self.registrationService = registrationService
        self.bluetoothNursery = bluetoothNursery
        self.session = session
        self.contactEventsUploader = contactEventsUploader
        self.uiQueue = uiQueue

        statusViewController = StatusViewController.instantiate()
        statusViewController.inject(
            persistence: persistence,
            registrationService: registrationService,
            contactEventsUploader: contactEventsUploader,
            notificationCenter: notificationCenter,
            linkingIdManager: linkingIdManager,
            statusProvider: statusProvider
        )
        
        notificationCenter.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        remoteNotificationManager.dispatcher.registerHandler(forType: .status) { (userInfo, completionHandler) in
            persistence.potentiallyExposed = Date()
            self.statusViewController.potentiallyExposed = Date()
            completionHandler(.newData)
        }
    }

    deinit {
        notificationCenter.removeObserver(self)
        remoteNotificationManager.dispatcher.removeHandler(forType: .status)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        showFirstView()
    }
    
    // MARK: - Routing
    func showFirstView() {
        if persistence.registration != nil {
            show(viewController: statusViewController)
        } else {
            let onboardingViewController = OnboardingViewController.instantiate()
            let env = OnboardingEnvironment(persistence: persistence, authorizationManager: authorizationManager, remoteNotificationManager: remoteNotificationManager, notificationCenter: NotificationCenter.default)
            let coordinator = OnboardingCoordinator(persistence: persistence, authorizationManager: authorizationManager, bluetoothNursery: bluetoothNursery)
            
            onboardingViewController.inject(env: env, coordinator: coordinator, bluetoothNursery: bluetoothNursery, uiQueue: self.uiQueue) {
                self.show(viewController: self.statusViewController)
            }
            
            onboardingViewController.showIn(container: self)
        }
    }
    
    @objc func applicationDidBecomeActive(_ notification: NSNotification) {
        guard children.first as? OnboardingViewController == nil else {
            // The onboarding flow has its own handling for setup problems, and if we present them from here
            // during onboarding then there will likely be two of them shown at the same time.
            return
        }
        
        let checker = SetupChecker(authorizationManager: authorizationManager, bluetoothNursery: bluetoothNursery)
        checker.check { problem in
            self.uiQueue.sync {
                self.dismissSetupError()
                guard let problem = problem else { return }
                
                switch problem {
                case .bluetoothOff:
                    let vc = BluetoothOffViewController.instantiate()
                    self.showSetupError(viewController: vc)
                case .bluetoothPermissions:
                    let vc = BluetoothPermissionDeniedViewController.instantiate()
                    self.showSetupError(viewController: vc)
                case .notificationPermissions:
                    let vc = NotificationPermissionDeniedViewController.instantiate()
                    self.showSetupError(viewController: vc)
                }
            }
        }
    }
    
    private func showSetupError(viewController: UIViewController) {
        self.presentedSetupErorrViewController = viewController
        self.present(viewController, animated: true)
    }
    
    private func dismissSetupError() {
        if self.presentedSetupErorrViewController != nil {
            self.dismiss(animated: true)
        }
    }
    
    // MARK: - Debug view controller management
    
    #if DEBUG || INTERNAL
    var previouslyPresentedViewController: UIViewController?

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard type(of: presentedViewController) != DebugViewController.self else { return }
        
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

        statusViewController.diagnosis = persistence.selfDiagnosis
        statusViewController.potentiallyExposed = persistence.potentiallyExposed

        if let vc = previouslyPresentedViewController {
            present(vc, animated: true)
        }
    }

    private func showDebugView() {
        let storyboard = UIStoryboard(name: "Debug", bundle: Bundle(for: Self.self))
        guard let tabBarVC = storyboard.instantiateInitialViewController() as? UITabBarController,
            let navVC = tabBarVC.viewControllers?.first as? UINavigationController,
            let debugVC = navVC.viewControllers.first as? DebugViewController else { return }
        
        debugVC.inject(persisting: persistence,
                       bluetoothNursery: bluetoothNursery,
                       contactEventRepository: bluetoothNursery.contactEventRepository,
                       contactEventPersister: bluetoothNursery.contactEventPersister,
                       contactEventsUploader: contactEventsUploader)
        
        present(tabBarVC, animated: true)
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
