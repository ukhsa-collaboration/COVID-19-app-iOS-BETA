//
//  PermissionsViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import Logging
import CoreBluetooth


class PermissionsViewController: UIViewController, Storyboarded {
    static let storyboardName = "Onboarding"

    private var authManager: AuthorizationManaging! = nil
    private var remoteNotificationManager: RemoteNotificationManager! = nil
    private var uiQueue: TestableQueue! = nil
    private var continueHandler: (() -> Void)! = nil
    private var bluetoothNursery: BluetoothNursery!
    
    @IBOutlet var continueButton: PrimaryButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    func inject(
        authManager: AuthorizationManaging,
        remoteNotificationManager: RemoteNotificationManager,
        bluetoothNursery: BluetoothNursery,
        uiQueue: TestableQueue,
        continueHandler: @escaping () -> Void
    ) {
        self.authManager = authManager
        self.remoteNotificationManager = remoteNotificationManager
        self.bluetoothNursery = bluetoothNursery
        self.uiQueue = uiQueue
        self.continueHandler = continueHandler
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.isHidden = true
        
        if authManager.bluetooth == .allowed {
            // If we get here, it most likely means that the user just went through the following flow:
            // 1. Visited this screen
            // 2. Denied Bluetooth permission
            // 3. Was shown the screen explaining why we need permission
            // 4. Granted permission
            // 5. Was redirected here.
            //
            // Prompt for notification permissions right away, to save taps and not make the user wonder
            // why they're having to go through this part of the flow a second time.
            maybeRequestNotificationPermissions()
        }
    }

    @IBAction func didTapContinue() {
        continueButton.isHidden = true
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        
        #if targetEnvironment(simulator)
        let bluetoothAuth = BluetoothAuthorizationStatus.allowed
        #else
        let bluetoothAuth = authManager.bluetooth
        #endif
        
        if bluetoothAuth == .notDetermined {
            requestBluetoothPermissions()
        } else {
            maybeRequestNotificationPermissions()
        }

    }

    // MARK: - Private

    private func requestBluetoothPermissions() {
        #if targetEnvironment(simulator)

        // There's no Bluetooth on the Simulator, so skip
        // directly to asking for notification permissions.
        continueHandler()
        
        #else

        // Trigger the permissions prompt
        bluetoothNursery.createListener()
        // Don't query the status until the user has responded
        bluetoothNursery.stateObserver!.observe { [weak self] _ in
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
        
        #endif
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
                    fatalError()
                }
            }
        }
    }
}

// MARK: - Logger
private let logger = Logger(label: "ViewController")
