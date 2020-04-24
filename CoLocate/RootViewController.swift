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
            notificationCenter: notificationCenter
        )
        
        notificationCenter.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        remoteNotificationManager.dispatcher.registerHandler(forType: .potentialDisagnosis) { (userInfo, completionHandler) in
            persistence.potentiallyExposed = true
            self.statusViewController.potentiallyExposed = true
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
            let coordinator = OnboardingCoordinator(persistence: persistence, authorizationManager: authorizationManager, bluetoothNursery: bluetoothNursery)
            
            onboardingViewController.inject(env: env, coordinator: coordinator, bluetoothNursery: bluetoothNursery, uiQueue: self.uiQueue) {
                self.show(viewController: self.statusViewController)
            }
            
            onboardingViewController.showIn(container: self)
        }
    }
    
    @objc func applicationDidBecomeActive(_ notification: NSNotification) {
        guard self.persistence.registration != nil else { return }
        
        self.dismissSetupErorr()

        authorizationManager.notifications { [weak self] notificationStatus in
            guard let self = self else { return }

            self.uiQueue.sync {
                if notificationStatus == .denied {
                    let vc = NotificationPermissionDeniedViewController.instantiate()
                    self.showSetupError(viewController: vc)
                } else if self.authorizationManager.bluetooth == .denied {
                    let vc = BluetoothPermissionDeniedViewController.instantiate()
                    self.showSetupError(viewController: vc)
                } else if let btObserver = self.bluetoothNursery.stateObserver {
                    btObserver.notifyOnStateChanges { [weak self] btState in
                        guard let self = self else { return .stopObserving }

                        switch btState {
                        case .unknown:
                            return .keepObserving
                        case .poweredOff:
                            let vc = BluetoothOffViewController.instantiate()
                            vc.inject(notificationCenter: self.notificationCenter, uiQueue: self.uiQueue, continueHandler: nil)
                            self.showSetupError(viewController: vc)
                            return .stopObserving
                        default:
                            return .stopObserving
                        }
                    }
                }                    
            }
        }
    }
    
    private func showSetupError(viewController: UIViewController) {
        self.presentedSetupErorrViewController = viewController
        self.present(viewController, animated: true)
    }
    
    private func dismissSetupErorr() {
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
        
        debugVC.inject(persisting: persistence, contactEventRepository: bluetoothNursery.contactEventRepository, contactEventPersister: bluetoothNursery.contactEventPersister, contactEventsUploader: contactEventsUploader)
        
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
