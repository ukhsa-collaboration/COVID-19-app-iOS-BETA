//
//  BluetoothStateObserver.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import CoreBluetooth

protocol BluetoothStateObserver {
    func state() -> CBManagerState
    var delegate: BluetoothStateObserverDelegate? { get set }
}

protocol BluetoothStateObserverDelegate {
    func bluetoothStateObserver(_ sender: BluetoothStateObserver, didChangeState state: CBManagerState)
}

// Wraps CBCentralManager's state discovery functionality, mainly for testability
class ConcreteBluetoothStateObserver: NSObject, BluetoothStateObserver, CBCentralManagerDelegate {
    
    private var centralManager: CBCentralManager?
    var delegate: BluetoothStateObserverDelegate?
        
    func state() -> CBManagerState {
        // Constructing a CBCentralManager triggers a permissions prompt if the user hasn't
        // already granted permission, so don't create it until we need to. This gives us a
        // chance to show our own UI first.
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
        }
        
        return centralManager!.state
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        delegate?.bluetoothStateObserver(self, didChangeState: central.state)
    }

}
