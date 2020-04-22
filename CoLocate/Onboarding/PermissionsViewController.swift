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
    var bluetoothNursery: StartsBroadcasting!
    @IBOutlet private var continueButton: PrimaryButton!
    private var isRequestingPermissions = false
    
    func inject(
        authManager: AuthorizationManaging,
        remoteNotificationManager: RemoteNotificationManager,
        bluetoothNursery: StartsBroadcasting,
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
        guard !isRequestingPermissions else { return }
        isRequestingPermissions = true
        
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

        bluetoothNursery.startBroadcaster(stateDelegate: self)
        
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

// MARK: - BTLEBroadcasterStateDelegate
extension PermissionsViewController: BTLEBroadcasterStateDelegate {
    func btleBroadcaster(_ broadcaster: BTLEBroadcaster, didUpdateState state: CBManagerState) {
        switch authManager.bluetooth {
        case .notDetermined:
            return
        case .denied:
            self.continueHandler()
        case .allowed:
            maybeRequestNotificationPermissions()
        }
    }
    
}

// MARK: - Logger
private let logger = Logger(label: "ViewController")
