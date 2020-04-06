//
//  BTLEListener.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CoreBluetooth
import Logging

protocol BTLEPeripheral {
    var identifier: UUID { get }
}

extension CBPeripheral: BTLEPeripheral {
}

protocol BTLEListenerDelegate {
    func btleListener(_ listener: BTLEListener, didConnect peripheral: BTLEPeripheral)
    func btleListener(_ listener: BTLEListener, didDisconnect peripheral: BTLEPeripheral, error: Error?)
    func btleListener(_ listener: BTLEListener, didFindSonarId sonarId: UUID, forPeripheral peripheral: BTLEPeripheral)
    func btleListener(_ listener: BTLEListener, didReadRSSI RSSI: Int, forPeripheral peripheral: BTLEPeripheral)
    func btleListener(_ listener: BTLEListener, shouldReadRSSIFor peripheral: BTLEPeripheral) -> Bool
}

protocol BTLEListenerStateDelegate {
    func btleListener(_ listener: BTLEListener, didUpdateState state: CBManagerState)
}

protocol BTLEListener {
    func start(stateDelegate: BTLEListenerStateDelegate?, delegate: BTLEListenerDelegate?)
}

class ConcreteBTLEListener: NSObject, BTLEListener, CBCentralManagerDelegate, CBPeripheralDelegate {

    let logger = Logger(label: "BTLE")
    
    let rssiSamplingInterval: TimeInterval = 20.0
    
    var stateDelegate: BTLEListenerStateDelegate?
    var delegate: BTLEListenerDelegate?
    var contactEventRecorder: ContactEventRecorder
    
    var peripherals: [UUID: CBPeripheral] = [:]

    init(contactEventRecorder: ContactEventRecorder) {
        self.contactEventRecorder = contactEventRecorder
    }

    func start(stateDelegate: BTLEListenerStateDelegate?, delegate: BTLEListenerDelegate?) {
        self.stateDelegate = stateDelegate
        self.delegate = delegate
    }
    
    // MARK: CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        logger.info("state: \(central.state)")
        
        stateDelegate?.btleListener(self, didUpdateState: central.state)
        
        switch (central.state) {
                
        case .poweredOn:
            central.scanForPeripherals(withServices: [ConcreteBTLEBroadcaster.sonarServiceUUID])

        default:
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        logger.info("willRestoreState for central \(central)")
        
        for peripheral in (dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] ?? []) {
            peripherals[peripheral.identifier] = peripheral
            peripheral.delegate = self
        }
    }
        
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        logger.info("\(peripheral.identifier) (\(peripheral.name ?? "unknown")), advertismentData: \(advertisementData)")

        if peripherals[peripheral.identifier] == nil {
            peripherals[peripheral.identifier] = peripheral
        }
        central.connect(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.info("\(peripheral.identifier) (\(peripheral.name ?? "unknown"))")

        delegate?.btleListener(self, didConnect: peripheral)
        
        peripheral.delegate = self
        peripheral.readRSSI()
        peripheral.discoverServices([ConcreteBTLEBroadcaster.sonarServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        logger.info("\(peripheral.identifier) (\(peripheral.name ?? "unknown"))")
        if let error = error {
            logger.info("didDisconnectPeripheral error: \(error)")
        }
        delegate?.btleListener(self, didDisconnect: peripheral, error: error)
                
        peripherals[peripheral.identifier] = nil
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        guard error == nil else {
            logger.info("didReadRSSI error: \(error!)")
            return
        }
        logger.info("\(peripheral.identifier) (\(peripheral.name ?? "unknown")), RSSI: \(RSSI)")

        delegate?.btleListener(self, didReadRSSI: RSSI.intValue, forPeripheral: peripheral)
        
        if delegate?.btleListener(self, shouldReadRSSIFor: peripheral) ?? false {
            Timer.scheduledTimer(withTimeInterval: rssiSamplingInterval, repeats: false) { timer in
                peripheral.readRSSI()
            }
        }
    }
    
    // MARK: CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        logger.info("\(peripheral.identifier) (\(peripheral.name ?? "unknown") invalidatedServices:")
        for service in invalidatedServices {
            logger.info("\t\(service)\n")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            logger.info("didDiscoverServices error: \(error!)")
            return
        }
        
        guard let services = peripheral.services, services.count > 0 else {
            logger.info("No services discovered for peripheral \(peripheral.identifier) (\(peripheral.name ?? "unknown"))")
            return
        }
        
        guard let sonarService = services.first(where: {$0.uuid == ConcreteBTLEBroadcaster.sonarServiceUUID}) else {
            logger.info("Sonar service not discovered for \(peripheral.identifier) (\(peripheral.name ?? "unknown")")
            return
        }

        logger.info("Sonar service found: \(sonarService)")
        peripheral.discoverCharacteristics([ConcreteBTLEBroadcaster.sonarIdCharacteristicUUID], for: sonarService)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            logger.info("didDiscoverCharacteristics error: \(error!)")
            return
        }
        
        guard let characteristics = service.characteristics, characteristics.count > 0 else {
            logger.info("No characteristics discovered for service \(service)")
            return
        }
        
        guard let sonarIdCharacteristic = characteristics.first(where: {$0.uuid == ConcreteBTLEBroadcaster.sonarIdCharacteristicUUID}) else {
            logger.info("sonarId characteristic not discovered for peripheral \(peripheral)")
            return
        }

        logger.info("found sonarId characteristic: \(sonarIdCharacteristic)")
        peripheral.readValue(for: sonarIdCharacteristic)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            logger.info("updatingValueFor characteristic \(characteristic): \(error!)")
            return
        }

        logger.info("didUpdateValueFor characteristic: \(characteristic)")

        guard let data = characteristic.value else {
            logger.info("No data found in characteristic.")
            return
        }

        guard characteristic.uuid == ConcreteBTLEBroadcaster.sonarIdCharacteristicUUID else {
            return
        }

        let sonarId = UUID(uuidString: CBUUID(data: data).uuidString)!
        delegate?.btleListener(self, didFindSonarId: sonarId, forPeripheral: peripheral)
    }

}
