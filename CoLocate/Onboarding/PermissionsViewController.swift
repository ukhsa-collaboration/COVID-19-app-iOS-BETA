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
    var pushNotificationManager: PushNotificationManager = ConcretePushNotificationManager()
    var persistence = Persistence.shared
    var uiQueue: TestableQueue = DispatchQueue.main

    // Hold onto the Bluetooth manager for the sole
    // purpose of retaining it in memory for the
    // lifespan of this view controller.
    var bluetoothManager: BluetoothManager?

    private var allowedBluetooth = false
    
    @IBAction func didTapContinue(_ sender: UIButton) {
        requestBluetoothPermissions()
    }

    private func requestBluetoothPermissions() {
        #if targetEnvironment(simulator)
        requestNotificationPermissions()
        #else
        bluetoothManager = CBPeripheralManager(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionShowPowerAlertKey: true])
        #endif
    }

    private func checkBluetoothAuth() {
        guard authManager.bluetooth == .allowed, !allowedBluetooth else { return }
        allowedBluetooth = true

        requestNotificationPermissions()
    }

    private func requestNotificationPermissions() {
        pushNotificationManager.requestAuthorization { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let granted):
                if granted {
                    self.uiQueue.async {
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

// MARK: - CBCentralManagerDelegate
extension PermissionsViewController: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        checkBluetoothAuth()
    }
}

// MARK: - Testable

protocol BluetoothManager {}
extension CBManager: BluetoothManager {}
