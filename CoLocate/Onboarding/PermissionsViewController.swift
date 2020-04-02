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
    static let storyboardName = "Onboarding"

    var authManager = AuthorizationManager()
    var remoteNotificationManager: RemoteNotificationManager = ConcreteRemoteNotificationManager()
    var persistence = Persistence.shared
    var uiQueue: TestableQueue = DispatchQueue.main

    // Hold onto the Bluetooth manager for the sole
    // purpose of retaining it in memory for the
    // lifespan of this view controller.
    private var bluetoothManager: BluetoothManager?

    private var bluetoothDetermined = false // sentinel so we only request notification permissions once
    
    @IBAction func didTapContinue(_ sender: UIButton) {
        sender.isEnabled = false
        requestBluetoothPermissions()
    }

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

        bluetoothManager = CBPeripheralManager(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionShowPowerAlertKey: true])
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
                    print("Error requesting notification permissions: \(error)")
                    fatalError()
                }
            }
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension PermissionsViewController: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch authManager.bluetooth {
        case .notDetermined:
            return
        case .allowed, .denied:
            bluetoothDetermined = true
            requestNotificationPermissions()
        }
    }
}

// MARK: - Testable

protocol BluetoothManager {}
extension CBManager: BluetoothManager {}
