//
//  CBManagerAdapter.swift
//  Sonar
//
//  Created by NHSX on 16/6/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CoreBluetooth

class SonarBTConnectionEvent {
    private let cbConnectionEvent: CBConnectionEvent
    
    init(_ connectionEvent: CBConnectionEvent) {
        self.cbConnectionEvent = connectionEvent
    }
}

protocol SonarBTCentralManagerDelegate: class {
    func centralManagerDidUpdateState(_ central: SonarBTCentralManager)
    func centralManager(_ central: SonarBTCentralManager, willRestoreState dict: [String : Any])
    func centralManager(_ central: SonarBTCentralManager, didConnect peripheral: SonarBTPeripheral)
    func centralManager(_ central: SonarBTCentralManager, didFailToConnect peripheral: SonarBTPeripheral, error: Error?)
    func centralManager(_ central: SonarBTCentralManager, didDisconnectPeripheral peripheral: SonarBTPeripheral, error: Error?)
    func centralManager(_ central: SonarBTCentralManager, didDiscover peripheral: SonarBTPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
    func centralManager(_ central: SonarBTCentralManager, connectionEventDidOccur event: SonarBTConnectionEvent, for peripheral: SonarBTPeripheral)
}

class SonarBTCentralManager: NSObject {
    private let cbManager: CBCentralManager
    private weak var delegate: SonarBTCentralManagerDelegate?
    private weak var peripheralDelegate: SonarBTPeripheralDelegate?

    public init(delegate: SonarBTCentralManagerDelegate?, peripheralDelegate: SonarBTPeripheralDelegate?, queue: DispatchQueue?, options: [String : Any]? = nil) {
        self.delegate = delegate
        self.peripheralDelegate = peripheralDelegate
        cbManager = CBCentralManager(delegate: nil, queue: queue, options: options)
        super.init()
        cbManager.delegate = self
    }
}

extension SonarBTCentralManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        delegate?.centralManagerDidUpdateState(self)
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        delegate?.centralManager(self, willRestoreState: dict)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        delegate?.centralManager(self, didConnect: SonarBTPeripheral(peripheral, delegate: peripheralDelegate))
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        delegate?.centralManager(self, didFailToConnect: SonarBTPeripheral(peripheral, delegate: peripheralDelegate), error: error)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        delegate?.centralManager(self, didDisconnectPeripheral: SonarBTPeripheral(peripheral, delegate: peripheralDelegate), error: error)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        delegate?.centralManager(self, didDiscover: SonarBTPeripheral(peripheral, delegate: peripheralDelegate), advertisementData: advertisementData, rssi: RSSI)
    }
    
    func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral) {
        delegate?.centralManager(self, connectionEventDidOccur: SonarBTConnectionEvent(event), for: SonarBTPeripheral(peripheral, delegate: peripheralDelegate))
    }
}
