//
//  PermissionsViewController.swift
//  Sonar
//
//  Created by NHSX on 12.03.20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import Logging

class PermissionsViewController: UIViewController, Storyboarded {
    static let storyboardName = "Onboarding"

    private var authManager: AuthorizationManaging! = nil
    private var remoteNotificationManager: RemoteNotificationManager! = nil
    private var uiQueue: TestableQueue! = nil
    private var continueHandler: (() -> Void)! = nil
    private var bluetoothNursery: BluetoothNursery! = nil
    private var persistence: Persisting! = nil
    
    @IBOutlet var continueButton: PrimaryButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    func inject(
        authManager: AuthorizationManaging,
        remoteNotificationManager: RemoteNotificationManager,
        bluetoothNursery: BluetoothNursery,
        persistence: Persisting,
        uiQueue: TestableQueue,
        continueHandler: @escaping () -> Void
    ) {
        self.authManager = authManager
        self.remoteNotificationManager = remoteNotificationManager
        self.bluetoothNursery = bluetoothNursery
        self.persistence = persistence
        self.uiQueue = uiQueue
        self.continueHandler = continueHandler
    }
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        activityIndicator.isHidden = true
        
        authManager.waitForDeterminedBluetoothAuthorizationStatus { [weak self] _ in
            guard let self = self else {
                return
            }

            // If we get here, it likely means that one of two things happend:
            // * This is the "happy path" on iOS 12. We need to prompt for notification permissions.
            // * The user is on iOS 13 and went through the folloiwng flow:
            //    1. Visited this screen
            //    2. Denied Bluetooth permission
            //    3. Was shown the screen explaining why we need permission
            //    4. Granted permission
            //    5. Was redirected here.
            // In the iOS 13 case, prompting for notification permisisons right now saves taps and
            // prevents the user from wondering why they have to go through this part of the flow
            // a second time.
            self.maybeRequestNotificationPermissions()
        }
    }

    @IBAction func didTapContinue() {
        continueButton.isHidden = true
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()

        persistence.bluetoothPermissionRequested = true
        
        #if targetEnvironment(simulator)

            // There's no Bluetooth on the Simulator, so skip
            // directly to asking for notification permissions.
            maybeRequestNotificationPermissions()
        
        #else
            requestBluetoothPermissions()
        #endif
    }

    // MARK: - Private

    private func requestBluetoothPermissions() {
        // observe, but don't ask for permissions yet
        // this will not trigger the prompt
        bluetoothNursery.stateObserver.observe { [weak self] _ in
            guard let self = self else { return .stopObserving }

            switch self.authManager.bluetooth {
            case .notDetermined:
                return .keepObserving
            case .denied:
                self.continueHandler()
                return .stopObserving
            case .allowed:
                self.maybeRequestNotificationPermissions()
                return .stopObserving
            }
        }

        // Trigger the permissions prompt
        bluetoothNursery.startBluetooth(registration: nil)
    }

    private func maybeRequestNotificationPermissions() {
        authManager.notifications { [weak self] status in
            guard let self = self else { return }

            // If we've already asked for notification permissions, bail
            // out to let the OnboardingViewController figure out how to
            // deal with it.
            guard status == .notDetermined else {
                self.uiQueue.async {
                    self.continueHandler()
                }
                return
            }

            self.remoteNotificationManager.requestAuthorization { result in
                switch result {
                case .success:
                    self.uiQueue.async {
                        self.continueHandler()
                    }
                case .failure(let error):
                    // We have no idea what would cause an error here.
                    logger.critical("Error requesting notification permissions: \(error)")
                    assertionFailure("Error requesting notification permissions: \(error)")
                }
            }
        }
    }
}

// MARK: - Logger
private let logger = Logger(label: "ViewController")
