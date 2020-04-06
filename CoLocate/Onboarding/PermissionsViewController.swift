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

    var authManager: AuthorizationManaging = AuthorizationManager()
    var remoteNotificationManager: RemoteNotificationManager = ConcreteRemoteNotificationManager()
    var persistence = Persistence.shared
    var uiQueue: TestableQueue = DispatchQueue.main
    var bluetoothNursery: BluetoothNursery = (UIApplication.shared.delegate as! AppDelegate).bluetoothNursery

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

        bluetoothNursery.startListener(stateDelegate: self)
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
                    self.performSegue(withIdentifier: "unwindFromPermissions", sender: self)
                }
                return
            }

            self.remoteNotificationManager.requestAuthorization { result in
                switch result {
                case .success:
                    self.uiQueue.async {
                        self.performSegue(withIdentifier: "unwindFromPermissions", sender: self)
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

// MARK: - BTLEListenerStateDelegate
extension PermissionsViewController: BTLEListenerStateDelegate {
    
    func btleListener(_ listener: BTLEListener, didUpdateState state: CBManagerState) {
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
