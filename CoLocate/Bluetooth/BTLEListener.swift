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
    func btleListener(_ listener: BTLEListener, didFind sonarId: Data, forPeripheral peripheral: BTLEPeripheral)
    func btleListener(_ listener: BTLEListener, didReadRSSI RSSI: Int, forPeripheral peripheral: BTLEPeripheral)
}

protocol BTLEListenerStateDelegate {
    func btleListener(_ listener: BTLEListener, didUpdateState state: CBManagerState)
}

protocol BTLEListener {
    func start(stateDelegate: BTLEListenerStateDelegate?, delegate: BTLEListenerDelegate?)
    func connect(_ peripheral: BTLEPeripheral)
}

class ConcreteBTLEListener: NSObject, BTLEListener, CBCentralManagerDelegate, CBPeripheralDelegate {

    let logger = Logger(label: "BTLE")
    
    let rssiSamplingInterval: TimeInterval = 20.0
    
    let persistence: Persistence
    
    var stateDelegate: BTLEListenerStateDelegate?
    var delegate: BTLEListenerDelegate?
    
    var central: CBCentralManager?
    
    var peripherals: [UUID: CBPeripheral] = [:]
    
    init(persistence: Persistence) {
        self.persistence = persistence
    }

    func start(stateDelegate: BTLEListenerStateDelegate?, delegate: BTLEListenerDelegate?) {
        self.stateDelegate = stateDelegate
        self.delegate = delegate
    }

    func connect(_ peripheral: BTLEPeripheral) {
        guard let coreBluetoothPeripheral = peripherals[peripheral.identifier] else {
            logger.info("can't connect to unknown peripheral with identifier \(peripheral.identifier)")
            return
        }
        
        central?.connect(coreBluetoothPeripheral)
    }
    
    // MARK: CBCentralManagerDelegate
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        guard let restoredPeripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] else {
            logger.info("no peripherals to restore for \(central)")
            return
        }
        
        logger.info("restoring \(restoredPeripherals.count) peripherals for central \(central)")
        for peripheral in restoredPeripherals {
            peripherals[peripheral.identifier] = peripheral
            peripheral.delegate = self
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        logger.info("state: \(central.state)")
        
        stateDelegate?.btleListener(self, didUpdateState: central.state)
        
        switch (central.state) {
                
        case .poweredOn:
            self.central = central
            
            // Ensure all "connected" peripherals are properly connected after state restoration
            for peripheral in peripherals.values {
                guard peripheral.state == .connected else {
                    logger.info("attempting connection to peripheral \(peripheral.identifierWithName) in state \(peripheral.state)")
                    central.connect(peripheral)
                    continue
                }
                guard let sonarIdService = peripheral.services?.sonarIdService() else {
                    logger.info("discovering services for peripheral \(peripheral.identifierWithName)")
                    peripheral.discoverServices([ConcreteBTLEBroadcaster.sonarServiceUUID])
                    continue
                }
                guard let sonarIdCharacteristic = sonarIdService.characteristics?.sonarIdCharacteristic() else {
                    logger.info("discovering characteristics for peripheral \(peripheral.identifierWithName)")
                    peripheral.discoverCharacteristics([ConcreteBTLEBroadcaster.sonarIdCharacteristicUUID], for: sonarIdService)
                    continue
                }
                logger.info("reading sonarId from fully-connected peripheral \(peripheral.identifierWithName)")
                peripheral.readValue(for: sonarIdCharacteristic)
            }
            
            central.scanForPeripherals(withServices: [ConcreteBTLEBroadcaster.sonarServiceUUID])

        default:
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        logger.info("peripheral \(peripheral.identifierWithName) discovered at RSSI = \(RSSI)")
        
        peripherals[peripheral.identifier] = peripheral
        delegate?.btleListener(self, didReadRSSI: RSSI.intValue, forPeripheral: peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.info("\(peripheral.identifierWithName)")

        peripheral.delegate = self
        peripheral.discoverServices([ConcreteBTLEBroadcaster.sonarServiceUUID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            logger.info("\(peripheral.identifierWithName) error: \(error)")
        } else {
            logger.info("\(peripheral.identifierWithName)")
        }
                
        peripherals[peripheral.identifier] = nil
    }
    
    // MARK: CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        logger.info("\(peripheral.identifierWithName) invalidatedServices:")
        for service in invalidatedServices {
            logger.info("\t\(service)\n")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            logger.info("error: \(error!)")
            return
        }
        
        guard let services = peripheral.services, services.count > 0 else {
            logger.info("No services discovered for peripheral \(peripheral.identifierWithName)")
            return
        }
        
        guard let sonarIdService = services.sonarIdService() else {
            logger.info("Sonar service not discovered for \(peripheral.identifierWithName)")
            return
        }

        logger.info("sonarId service found: \(sonarIdService)")
        peripheral.discoverCharacteristics([ConcreteBTLEBroadcaster.sonarIdCharacteristicUUID], for: sonarIdService)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            logger.info("error: \(error!)")
            return
        }
        
        guard let characteristics = service.characteristics, characteristics.count > 0 else {
            logger.info("No characteristics discovered for service \(service)")
            return
        }
        
        guard let sonarIdCharacteristic = characteristics.sonarIdCharacteristic() else {
            logger.info("sonarId characteristic not discovered for peripheral \(peripheral.identifierWithName)")
            return
        }

        logger.info("sonarId characteristic found: \(sonarIdCharacteristic)")
        peripheral.readValue(for: sonarIdCharacteristic)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            logger.info("characteristic \(characteristic) error: \(error!)")
            return
        }

        guard characteristic.uuid == ConcreteBTLEBroadcaster.sonarIdCharacteristicUUID else {
            logger.info("characteristic \(characteristic) does not have correct UUID")
            return
        }

        guard let data = characteristic.value else {
            logger.info("no data found in characteristic \(characteristic)")
            return
        }

        guard data.count == BroadcastIdEncrypter.broadcastIdLength else {
            logger.info("characteristic value is not a valid sonarId, because it has length \(data.count). Expected \(BroadcastIdEncrypter.broadcastIdLength)")
            return
        }

        logger.info("successfully read sonarId from peripheral \(peripheral.identifierWithName), now disconnecting")
        delegate?.btleListener(self, didFind: data, forPeripheral: peripheral)
        central?.cancelPeripheralConnection(peripheral)
    }

}
