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
    var bluetoothNursery: BluetoothNursery = (UIApplication.shared.delegate as! AppDelegate).bluetoothNursery
    
    func inject(authManager: AuthorizationManaging, remoteNotificationManager: RemoteNotificationManager, uiQueue: TestableQueue, continueHandler: @escaping () -> Void) {
        self.authManager = authManager
        self.remoteNotificationManager = remoteNotificationManager
        self.uiQueue = uiQueue
        self.continueHandler = continueHandler
    }

    @IBAction func didTapContinue(_ sender: UIButton) {
        sender.isEnabled = false
        requestBluetoothPermissions()
    }

    // MARK: - Private

    private func requestBluetoothPermissions() {
        #if targetEnvironment(simulator)

        // There's no Bluetooth on the Simulator, so skip
        // directly to asking for notification permissions.
        requestNotificationPermissions()

        #else

        // Only ask for Bluetooth permissions if we haven't
        // already asked. If we have, we can skip to asking
        // for notification permissions.
        guard authManager.bluetooth == .notDetermined else {
            requestNotificationPermissions()
            return
        }

        bluetoothNursery.startBroadcaster(stateDelegate: self)
        #endif
    }

    private func requestNotificationPermissions() {
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
        case .allowed, .denied:
            requestNotificationPermissions()
        }
    }
    
}

// MARK: - Logger
private let logger = Logger(label: "ViewController")
