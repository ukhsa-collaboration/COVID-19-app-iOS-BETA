//
//  CBManagerAdapter.swift
//  Sonar
//
//  Created by NHSX on 16/6/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CoreBluetooth

class SonarBTDescriptor {
    private let cbDescriptor: CBDescriptor
    
    init(_ descriptor: CBDescriptor) {
        self.cbDescriptor = descriptor
    }
}

class SonarBTService {
    private let cbService: CBService
    
    init(_ service: CBService) {
        self.cbService = service
    }
}

protocol SonarBTPeripheralDelegate: class {
    func peripheral(_ peripheral: SonarBTPeripheral, didDiscoverServices error: Error?)
    func peripheral(_ peripheral: SonarBTPeripheral, didReadRSSI RSSI: NSNumber, error: Error?)
    func peripheral(_ peripheral: SonarBTPeripheral, didUpdateValueFor descriptor: SonarBTDescriptor, error: Error?)
    func peripheral(_ peripheral: SonarBTPeripheral, didDiscoverCharacteristicsFor service: SonarBTService, error: Error?)
}

class SonarBTPeripheral: NSObject {
    private let cbPeripheral: CBPeripheral
    private weak var delegate: SonarBTPeripheralDelegate?
    
    init(_ peripheral: CBPeripheral, delegate: SonarBTPeripheralDelegate?) {
        self.cbPeripheral = peripheral
        self.delegate = delegate
        super.init()
    }
}

extension SonarBTPeripheral: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        delegate?.peripheral(self, didDiscoverServices: error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        delegate?.peripheral(self, didReadRSSI: RSSI, error: error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        delegate?.peripheral(self, didUpdateValueFor: SonarBTDescriptor(descriptor), error: error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        delegate?.peripheral(self, didDiscoverCharacteristicsFor: SonarBTService(service), error: error)
    }
}

protocol SonarBTCentralManagerDelegate: class {
    func centralManagerDidUpdateState(_ central: SonarBTCentralManager)
    func centralManager(_ central: SonarBTCentralManager, willRestoreState dict: [String : Any])
    func centralManager(_ central: SonarBTCentralManager, didConnect peripheral: SonarBTPeripheral)
    func centralManager(_ central: SonarBTCentralManager, didFailToConnect peripheral: SonarBTPeripheral, error: Error?)
    func centralManager(_ central: SonarBTCentralManager, didDisconnectPeripheral peripheral: SonarBTPeripheral, error: Error?)
    func centralManager(_ central: SonarBTCentralManager, didDiscover peripheral: SonarBTPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
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
        self.delegate?.centralManagerDidUpdateState(self)
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        self.delegate?.centralManager(self, willRestoreState: dict)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.delegate?.centralManager(self, didConnect: SonarBTPeripheral(peripheral, delegate: peripheralDelegate))
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        self.delegate?.centralManager(self, didFailToConnect: SonarBTPeripheral(peripheral, delegate: peripheralDelegate), error: error)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.delegate?.centralManager(self, didDisconnectPeripheral: SonarBTPeripheral(peripheral, delegate: peripheralDelegate), error: error)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        self.delegate?.centralManager(self, didDiscover: SonarBTPeripheral(peripheral, delegate: peripheralDelegate), advertisementData: advertisementData, rssi: RSSI)
    }
}
