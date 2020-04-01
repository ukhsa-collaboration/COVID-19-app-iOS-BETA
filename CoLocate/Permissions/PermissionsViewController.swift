//
//  PermissionsViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import CoreBluetooth

class PermissionsViewController: UIViewController, Storyboarded {
    static let storyboardName = "Permissions"

    let authManager = AuthorizationManager()
    let notificationManager: PushNotificationManager = ConcretePushNotificationManager()
    let persistence = Persistence.shared

    weak var bluetoothReadyDelegate: BluetoothAvailableDelegate?
    
    @IBAction func didTapContinue(_ sender: UIButton) {
        requestBluetoothPermissions()
    }

    private func requestBluetoothPermissions() {
        #if targetEnvironment(simulator)
            requestNotificationPermissions()
        #else
            // TODO: Inject these?
            let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
            appDelegate.broadcaster.start(stateDelegate: self)
            appDelegate.listener.start(stateDelegate: self)
        #endif
    }

    private func checkBluetoothAuth() {
        guard authManager.bluetooth == .allowed else { return }

        if persistence.newOnboarding {
            requestNotificationPermissions()
        } else {
            bluetoothReadyDelegate?.bluetoothIsAvailable()
        }
    }

    private func requestNotificationPermissions() {
        notificationManager.requestAuthorization { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let granted):
                if granted {
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "unwindFromPermissions", sender: self)
                    }
                } else {
                    // We get here sometimes even after tapping "Allow", so maybe
                    // we should re-check permissions here after a short delay to
                    // see if it's a spurious false result?
                    fatalError()
                }
            case .failure(let error):
                print("Error requesting notification permissions: \(error)")
                fatalError()
            }
        }
    }
}

// MARK: - BTLEBroadcasterDelegate
extension PermissionsViewController: BTLEBroadcasterStateDelegate {
    func btleBroadcaster(_ broadcaster: BTLEBroadcaster, didUpdateState state: CBManagerState) {
        // Do we also need to wait for Bluetooth to be powered on here?

        checkBluetoothAuth()
    }
}

// MARK: - BTLEListenerDelegate
extension PermissionsViewController: BTLEListenerStateDelegate {
    func btleListener(_ listener: BTLEListener, didUpdateState state: CBManagerState) {
        // Do we also need to wait for Bluetooth to be powered on here?

        checkBluetoothAuth()
    }
}
