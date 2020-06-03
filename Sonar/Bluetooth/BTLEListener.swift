//
//  BTLEListener.swift
//  Sonar
//
//  Created by NHSX on 12.03.20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import CoreBluetooth
import Logging

protocol BTLEPeripheral {
    var identifier: UUID { get }
}

extension CBPeripheral: BTLEPeripheral {
}

protocol BTLEListenerDelegate {
    func btleListener(_ listener: BTLEListener, didFind broadcastPayload: IncomingBroadcastPayload, for peripheral: BTLEPeripheral)
    func btleListener(_ listener: BTLEListener, didReadRSSI RSSI: Int, for peripheral: BTLEPeripheral)
    func btleListener(_ listener: BTLEListener, didReadTxPower txPower: Int, for peripheral: BTLEPeripheral)
}

protocol BTLEListenerStateDelegate {
    func btleListener(_ listener: BTLEListener, didUpdateState state: CBManagerState)
}

protocol BTLEListener {
    func start(stateDelegate: BTLEListenerStateDelegate?, delegate: BTLEListenerDelegate?)
    func isHealthy() -> Bool
}

class ConcreteBTLEListener: NSObject, BTLEListener, CBCentralManagerDelegate, CBPeripheralDelegate {

    var broadcaster: Broadcaster
    var stateDelegate: BTLEListenerStateDelegate?
    var delegate: BTLEListenerDelegate?
    
    var peripherals: [UUID: CBPeripheral] = [:]
    
    // comfortably less than the ~10s background processing time Core Bluetooth gives us when it wakes us up
    private let keepaliveInterval: TimeInterval = 8.0
    
    private var lastKeepaliveDate: Date = Date.distantPast
    private var keepaliveTimer: DispatchSourceTimer?
    private let dateFormatter = ISO8601DateFormatter()
    private let queue: DispatchQueue
    
    init(broadcaster: Broadcaster, queue: DispatchQueue) {
        self.broadcaster = broadcaster
        self.queue = queue
    }

    func start(stateDelegate: BTLEListenerStateDelegate?, delegate: BTLEListenerDelegate?) {
        self.stateDelegate = stateDelegate
        self.delegate = delegate
    }


    // MARK: CBCentralManagerDelegate
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        if let restoredPeripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            logger.info("restoring \(restoredPeripherals.count) \(restoredPeripherals.count == 1 ? "peripheral" : "peripherals") for central \(central)")
            for peripheral in restoredPeripherals {
                peripherals[peripheral.identifier] = peripheral
                peripheral.delegate = self
            }
        } else {
            logger.info("no peripherals to restore for \(central)")
        }
        
        if let restoredScanningServices = dict[CBCentralManagerRestoredStateScanServicesKey] as? [CBUUID] {
            logger.info("restoring scanning for \(restoredScanningServices.count) \(restoredScanningServices.count == 1 ? "service" : "services") for central \(central)")
            for restoredScanningService in restoredScanningServices {
                logger.info("    service \(restoredScanningService.uuidString)")
            }
        } else {
            logger.info("no scanning restored for \(central)")
        }

        if let scanOptions = dict[CBCentralManagerRestoredStateScanOptionsKey] as? Dictionary<String, Any> {
            logger.info("restoring \(scanOptions.count) \(scanOptions.count == 1 ? "scanOption" : "scanOptions") for central \(central)")
            for scanOption in scanOptions {
                logger.info("    scanOption: \(scanOption.key), value: \(scanOption.value)")
            }
        } else {
            logger.info("no scanOptions restored for \(central)")
        }
        logger.info("central \(central.isScanning ? "is" : "is not") scanning")
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        logger.info("state: \(central.state)")
        
        stateDelegate?.btleListener(self, didUpdateState: central.state)
        
        switch (central.state) {
                
        case .poweredOn:
            
            // Reconnect to all the peripherals we found in willRestoreState (assume calling connect is idempotent)
            for peripheral in peripherals.values {
                central.connect(peripheral)
                if peripheral.state == .connected {
                    logger.info("reading rssi for .connected peripheral \(peripheral.identifierWithName)")
                    peripheral.readRSSI()
                }
            }
            
            central.scanForPeripherals(withServices: [Environment.sonarServiceUUID])

        default:
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let txPower = (advertisementData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber)?.intValue {
            logger.info("peripheral \(peripheral.identifierWithName) discovered with RSSI = \(RSSI), txPower = \(txPower)")
            delegate?.btleListener(self, didReadTxPower: txPower, for: peripheral)
        } else {
            logger.info("peripheral \(peripheral.identifierWithName) discovered with RSSI = \(RSSI)")            
        }
        
        if let savedPeripheral = peripherals[peripheral.identifier] {
            logger.info("saved peripheral \(savedPeripheral.identifierWithName) already in state \(savedPeripheral.state), calling connect again")
        }
        peripherals[peripheral.identifier] = peripheral
        central.connect(peripheral)        
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.info("peripheral \(peripheral.identifierWithName) connected")

        peripheral.delegate = self
        peripheral.readRSSI()
        peripheral.discoverServices([Environment.sonarServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        switch error {
            
        case (let error as CBATTError) where error.code == .unlikelyError:
            logger.info("peripheral \(peripheral.identifierWithName) error: \(error)")
            peripherals.removeValue(forKey: peripheral.identifier)
            central.cancelPeripheralConnection(peripheral)
            
        case (let error?):
            logger.info("peripheral \(peripheral.identifierWithName) error: \(error)")
            central.connect(peripheral)
            
        default:
            logger.info("peripheral \(peripheral.identifierWithName)")
            central.connect(peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            logger.info("attempting reconnection to peripheral \(peripheral.identifierWithName) after error: \(error)")
        } else {
            logger.info("attempting reconnection to peripheral \(peripheral.identifierWithName)")
        }
        central.connect(peripheral)
    }
    
    // MARK: CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        logger.info("peripheral \(peripheral.identifierWithName) invalidatedServices:")
        for service in invalidatedServices {
            logger.info("\t\(service)\n")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            logger.info("periperhal \(peripheral.identifierWithName) error: \(error!)")
            return
        }
        
        guard let services = peripheral.services, services.count > 0 else {
            logger.info("No services discovered for peripheral \(peripheral.identifierWithName), trying again...")
            // TODO: we need to rate-limit this, otherwise we spam the log and probably peoples' bluetoot stack
//            peripheral.discoverServices([Environment.sonarServiceUUID])
            return
        }
        
        guard let sonarIdService = services.sonarIdService() else {
            logger.info("sonarId service not discovered for peripheral \(peripheral.identifierWithName)")
            return
        }

        logger.info("discovering characteristics for peripheral \(peripheral.identifierWithName) with sonarId service \(sonarIdService)")
        let characteristics = [
            Environment.sonarIdCharacteristicUUID,
            Environment.keepaliveCharacteristicUUID
        ]
        peripheral.discoverCharacteristics(characteristics, for: sonarIdService)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            logger.info("periperhal \(peripheral.identifierWithName) error: \(error!)")
            return
        }
        
        guard let characteristics = service.characteristics, characteristics.count > 0 else {
            logger.info("no characteristics discovered for service \(service)")
            return
        }
        logger.info("\(characteristics.count) \(characteristics.count == 1 ? "characteristic" : "characteristics") discovered for service \(service): \(characteristics)")
        
        if let sonarIdCharacteristic = characteristics.sonarIdCharacteristic() {
            logger.info("reading sonarId from sonarId characteristic \(sonarIdCharacteristic)")
            peripheral.readValue(for: sonarIdCharacteristic)
            peripheral.setNotifyValue(true, for: sonarIdCharacteristic)
        } else {
            logger.info("sonarId characteristic not discovered for peripheral \(peripheral.identifierWithName)")
        }
        
        if let keepaliveCharacteristic = characteristics.keepaliveCharacteristic() {
            logger.info("subscribing to keepalive characteristic \(keepaliveCharacteristic)")
            peripheral.setNotifyValue(true, for: keepaliveCharacteristic)
        } else {
            logger.info("keepalive characteristic not discovered for peripheral \(peripheral.identifierWithName)")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            logger.info("characteristic \(characteristic) error: \(error!)")
            return
        }

        switch characteristic.value {
            
        case (let data?) where characteristic.uuid == Environment.sonarIdCharacteristicUUID:
            if data.count == BroadcastPayload.length {
                logger.info("read identity from peripheral \(peripheral.identifierWithName): \(data)")
                delegate?.btleListener(self, didFind: IncomingBroadcastPayload(data: data), for: peripheral)
            } else {
                logger.info("no identity ready from peripheral \(peripheral.identifierWithName)")
            }
            peripheral.readRSSI()
            
        case (let data?) where characteristic.uuid == Environment.keepaliveCharacteristicUUID:
            guard data.count == 1 else {
                logger.info("invalid keepalive value \(data)")
                return
            }
            
            let keepaliveValue = data.withUnsafeBytes { $0.load(as: UInt8.self) }
            logger.info("read keepalive value from peripheral \(peripheral.identifierWithName): \(keepaliveValue)")
            readRSSIAndSendKeepalive()
            
        case .none:
            logger.info("characteristic \(characteristic) has no data")
            
        default:
            logger.info("characteristic \(characteristic) has unknown uuid \(characteristic.uuid)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        guard error == nil else {
            logger.info("error: \(error!)")
            return
        }

        logger.info("read RSSI for \(peripheral.identifierWithName): \(RSSI)")
        delegate?.btleListener(self, didReadRSSI: RSSI.intValue, for: peripheral)
        readRSSIAndSendKeepalive()
    }

    private func readRSSIAndSendKeepalive() {
        guard Date().timeIntervalSince(lastKeepaliveDate) > keepaliveInterval else {
            logger.info("too soon, won't send keepalive (lastKeepalive = \(lastKeepaliveDate))")
            return
        }

        for peripheral in peripherals.values {
            guard peripheral.state == .connected else {
                logger.info("skipping RSSI for \(peripheral.identifierWithName) as it is in state \(peripheral.state)")
                continue
            }
            logger.info(" reading RSSI for \(peripheral.identifierWithName)")
            peripheral.readRSSI()
        }
        
        logger.info("scheduling keepalive")
        lastKeepaliveDate = Date()
        var keepaliveValue = UInt8.random(in: .min ... .max)
        let value = Data(bytes: &keepaliveValue, count: MemoryLayout.size(ofValue: keepaliveValue))
        keepaliveTimer = DispatchSource.makeTimerSource(queue: queue)
        keepaliveTimer?.setEventHandler {
            self.broadcaster.sendKeepalive(value: value)
        }
        keepaliveTimer?.schedule(deadline: .now() + keepaliveInterval)
        keepaliveTimer?.resume()
    }

    func isHealthy() -> Bool {
        guard keepaliveTimer != nil else { return false }
        guard stateDelegate != nil else { return false }
        guard delegate != nil else { return false }

        return true
    }
    
    fileprivate let logger: Logger = {
        var logger = Logger(label: "BTLE")
        #if BLE_LOGLEVEL_NODEBUG
        logger.logLevel = .notice
        #else
        logger.logLevel = .debug
        #endif
        return logger
    }()

}
