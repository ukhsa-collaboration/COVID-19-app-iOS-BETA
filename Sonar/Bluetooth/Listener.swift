//
//  BTLEListener.swift
//  Sonar
//
//  Created by NHSX on 12.03.20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import Logging

protocol Peripheral {
    var identifier: UUID { get }
}

extension SonarBTPeripheral: Peripheral {
}

protocol ListenerDelegate {
    func listener(_ listener: Listener, didFind broadcastPayload: IncomingBroadcastPayload, for peripheral: Peripheral)
    func listener(_ listener: Listener, didReadRSSI RSSI: Int, for peripheral: Peripheral)
    func listener(_ listener: Listener, didReadTxPower txPower: Int, for peripheral: Peripheral)
}

protocol ListenerStateDelegate {
    func listener(_ listener: Listener, didUpdateState state: SonarBTManagerState)
}

protocol Listener {
    func start(stateDelegate: ListenerStateDelegate?, delegate: ListenerDelegate?)
    func isHealthy() -> Bool
}

class BTLEListener: NSObject, Listener {
    var reconnectDelay: Int = 0

    var broadcaster: Broadcaster
    var stateDelegate: ListenerStateDelegate?
    var delegate: ListenerDelegate?
    
    var peripherals: [UUID: SonarBTPeripheral] = [:]
    
    private let keepaliveInterval: TimeInterval
    
    private var lastKeepaliveDate: Date = Date.distantPast
    private var keepaliveTimer: DispatchSourceTimer?
    private let dateFormatter = ISO8601DateFormatter()
    private let queue: DispatchQueue

    // comfortably less than the ~10s background processing time Core Bluetooth gives us when it wakes us up
    init(keepaliveInterval: TimeInterval = 8.0) {
        self.keepaliveInterval = keepaliveInterval
        
        let persistence = Persistence(
            secureRegistrationStorage: SecureRegistrationStorage(),
            broadcastKeyStorage: SecureBroadcastRotationKeyStorage(),
            monitor: NoOpAppMonitoring(),
            storageChecker: StorageChecker(service: "")
        )

        let broadcastPayloadService = SonarBroadcastPayloadService(
            storage: SecureBroadcastRotationKeyStorage(),
            persistence: persistence,
            encrypter: ConcreteBroadcastIdEncrypter())

        self.broadcaster = BTLEBroadcaster(broadcastPayloadService: broadcastPayloadService)
        self.queue = DispatchQueue(label: "BTLE Queue")
    }

    init(broadcaster: Broadcaster, queue: DispatchQueue, keepaliveInterval: TimeInterval = 8.0) {
        self.broadcaster = broadcaster
        self.queue = queue
        self.keepaliveInterval = keepaliveInterval
    }

    func start(stateDelegate: ListenerStateDelegate?, delegate: ListenerDelegate?) {
        self.stateDelegate = stateDelegate
        self.delegate = delegate
    }

    func isHealthy() -> Bool {
        guard keepaliveTimer != nil else { return false }
        guard stateDelegate != nil else { return false }
        guard delegate != nil else { return false }

        return true
    }
}

// MARK: SonarBTCentralManagerDelegate
extension BTLEListener: SonarBTCentralManagerDelegate {
    func centralManager(_ central: SonarBTCentralManager, willRestoreState dict: [String : Any]) {
        if let restoredPeripherals = dict[SonarBTCentralManagerRestoredStatePeripheralsKey] as? [SonarBTPeripheral] {
            logger.info("restoring \(restoredPeripherals.count) \(restoredPeripherals.count == 1 ? "peripheral" : "peripherals") for central \(central)")
            for peripheral in restoredPeripherals {
                peripherals[peripheral.identifier] = peripheral
                peripheral.delegate = self
            }
        } else {
            logger.info("no peripherals to restore for \(central)")
        }
        
        if let restoredScanningServices = dict[SonarBTCentralManagerRestoredStateScanServicesKey] as? [SonarBTUUID] {
            logger.info("restoring scanning for \(restoredScanningServices.count) \(restoredScanningServices.count == 1 ? "service" : "services") for central \(central)")
            for restoredScanningService in restoredScanningServices {
                logger.info("    service \(restoredScanningService.uuidString)")
            }
        } else {
            logger.info("no scanning restored for \(central)")
        }

        if let scanOptions = dict[SonarBTCentralManagerRestoredStateScanOptionsKey] as? Dictionary<String, Any> {
            logger.info("restoring \(scanOptions.count) \(scanOptions.count == 1 ? "scanOption" : "scanOptions") for central \(central)")
            for scanOption in scanOptions {
                logger.info("    scanOption: \(scanOption.key), value: \(scanOption.value)")
            }
        } else {
            logger.info("no scanOptions restored for \(central)")
        }
        logger.info("central \(central.isScanning ? "is" : "is not") scanning")
    }

    // dlb/br: Happy Case [HUB] - Entry Point
    func centralManagerDidUpdateState(_ central: SonarBTCentralManager) {
        logger.info("state: \(central.state)")
        
        stateDelegate?.listener(self, didUpdateState: central.state)
        
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
    
    func centralManager(_ central: SonarBTCentralManager, didDiscover peripheral: SonarBTPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        logger.info("advertisement data = \(advertisementData.debugDescription ??? "nil")")
        if let txPower = (advertisementData[SonarBTAdvertisementDataTxPowerLevelKey] as? NSNumber)?.intValue {
            logger.info("peripheral \(peripheral.identifierWithName) discovered with RSSI = \(RSSI), txPower = \(txPower)")
            delegate?.listener(self, didReadTxPower: txPower, for: peripheral)
        } else {
            logger.info("peripheral \(peripheral.identifierWithName) discovered with RSSI = \(RSSI)")            
        }
        
        if let savedPeripheral = peripherals[peripheral.identifier] {
            logger.info("saved peripheral \(savedPeripheral.identifierWithName) already in state \(savedPeripheral.state), calling connect again")
        }
        
        // Always connect to every advertisement we get; it doesn't (seem?) to be an issue to connect multiple times to the same device,
        // and when we guard against doing this by ignoring peripherals we already know about (even only ones in .connected state) we
        // end up missing (Android?) devices we've already seen before but aren't properly getting readings from. It seems the value of
        // peripheral.state does not give us any useful indication as to whether the connection is "live" or not
        // https://www.pivotaltracker.com/story/show/173132100
        peripherals[peripheral.identifier] = peripheral
        central.connect(peripheral)
    }
    
    func centralManager(_ central: SonarBTCentralManager, didConnect peripheral: SonarBTPeripheral) {
        logger.info("central.state \(central.state)")

        logger.info("peripheral \(peripheral.identifierWithName) connected")

        logger.info("BEFORE SETTING peripheral.delegate: \(String(describing: peripheral.delegate))")
        peripheral.delegate = self
        logger.info(" AFTER SETTING peripheral.delegate: \(String(describing: peripheral.delegate))")

        peripheral.readRSSI()
        peripheral.discoverServices([Environment.sonarServiceUUID])
    }
    
    func centralManager(_ central: SonarBTCentralManager, didFailToConnect peripheral: SonarBTPeripheral, error: Error?) {
        
            // From experience, some errors seem to be unrecoverable and we should not automatically
            // attempt to reconnect when we get them:
            switch error {
                
            // https://www.pivotaltracker.com/story/show/173149688
            case (let error as SonarBTError) where error.code.rawValue == 12: // CBError.Code.unknownDevice aka CBError.Code.unkownDevice
                logger.info("removing peripheral \(peripheral.identifierWithName) from connection list because of error: \(error)")
                peripherals.removeValue(forKey: peripheral.identifier)
                central.cancelPeripheralConnection(peripheral)
                
            // https://www.pivotaltracker.com/story/show/172576561
            case (let error as SonarBTATTError) where error.code == SonarBTATTError.Code.unlikelyError:
                logger.info("removing peripheral \(peripheral.identifierWithName) from connection list because of error: \(error)")
                peripherals.removeValue(forKey: peripheral.identifier)
                central.cancelPeripheralConnection(peripheral)
                
            case (let error?):
                logger.info("reconnecting to peripheral \(peripheral.identifierWithName) after error: \(error)")
                central.connect(peripheral)
                
            default:
                logger.info("reconnecting to peripheral \(peripheral.identifierWithName) after unknown error")
                central.connect(peripheral)
            }
    }

    func centralManager(_ central: SonarBTCentralManager, didDisconnectPeripheral peripheral: SonarBTPeripheral, error: Error?) {
        let delay = reconnectDelay == 0 ? "immediately" : "after \(reconnectDelay)s"
        if let error = error {
            logger.info("attempting to reconnect \(delay) to peripheral \(peripheral.identifierWithName) after error: \(error)")
        } else {
            logger.info("attempting to reconnect \(delay) to peripheral \(peripheral.identifierWithName)")
        }
        // iOS devices do not start advertising after being disconnected, so in order to ensure they reconnect if/when
        // they come back into range, we need to tell iOS to immediately reconnect
        
        if reconnectDelay == 0 {
            central.connect(peripheral)
        } else {
            queue.asyncAfter(deadline: .now() + .seconds(reconnectDelay)) {
                central.connect(peripheral)
            }
        }
    }

    func centralManager(_ central: SonarBTCentralManager, connectionEventDidOccur event: SonarBTConnectionEvent, for peripheral: SonarBTPeripheral) {
        logger.info("peripheral \(peripheral.identifierWithName) event: \(event)")
    }
}

// MARK: SonarBTPeripheralDelegate
extension BTLEListener: SonarBTPeripheralDelegate {
    func peripheral(_ peripheral: SonarBTPeripheral, didModifyServices invalidatedServices: [SonarBTService]) {
        logger.info("peripheral \(peripheral.identifierWithName) invalidatedServices:")
        for service in invalidatedServices {
            logger.info("\t\(service)\n")
        }
    }
    
    func peripheral(_ peripheral: SonarBTPeripheral, didDiscoverServices error: Error?) {
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
    
    func peripheral(_ peripheral: SonarBTPeripheral, didDiscoverCharacteristicsFor service: SonarBTService, error: Error?) {
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
    
    func peripheral(_ peripheral: SonarBTPeripheral, didUpdateNotificationStateFor characteristic: SonarBTCharacteristic, error: Error?) {
        guard error == nil else {
            logger.info("characteristic \(characteristic) error: \(error!)")
            return
        }
        logger.info("characteristic \(characteristic)")
    }

    func peripheral(_ peripheral: SonarBTPeripheral, didUpdateValueFor characteristic: SonarBTCharacteristic, error: Error?) {
        guard error == nil else {
            logger.info("characteristic \(characteristic) error: \(error!)")
            return
        }

        switch characteristic.value {
            
        case (let data?) where characteristic.uuid == Environment.sonarIdCharacteristicUUID:
            if data.count == BroadcastPayload.length {
                logger.info("read identity from peripheral \(peripheral.identifierWithName): \(PrintableBroadcastPayload(data))")
                delegate?.listener(self, didFind: IncomingBroadcastPayload(data: data), for: peripheral)
            } else {
                #if DEBUG || INTERNAL
                logger.info("no identity read from peripheral \(peripheral.identifierWithName) (value = '\(data.base64EncodedString())')")
                #else
                logger.info("no identity read from peripheral \(peripheral.identifierWithName) (value = \(data))")
                #endif
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
    
    func peripheral(_ peripheral: SonarBTPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        guard error == nil else {
            logger.info("error: \(error!)")
            return
        }

        logger.info("read RSSI for \(peripheral.identifierWithName): \(RSSI)")
        delegate?.listener(self, didReadRSSI: RSSI.intValue, for: peripheral)
        readRSSIAndSendKeepalive()
    }
    
    func peripheralDidUpdateName(_ peripheral: SonarBTPeripheral) {
        logger.info("peripheral \(peripheral.identifierWithName)")
    }
}

fileprivate extension BTLEListener {
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

        // TODO: Execution guaranteed from this call?
        keepaliveTimer = DispatchSource.makeTimerSource(queue: queue)
        keepaliveTimer?.setEventHandler { [unowned self] in
            self.broadcaster.sendKeepalive(value: value)
        }
        keepaliveTimer?.schedule(deadline: .now() + keepaliveInterval)
        keepaliveTimer?.resume()
    }
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
