//
//  BTLEBroadcaster.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit
import Logging

protocol BTLEBroadcaster {
    func sendKeepalive(value: Data)
    func updateIdentity()

    func isHealthy() -> Bool
}

class ConcreteBTLEBroadcaster: NSObject, BTLEBroadcaster, CBPeripheralManagerDelegate {
    
    static let sonarServiceUUID = CBUUID(string: "c1f5983c-fa94-4ac8-8e2e-bb86d6de9b21")
    static let sonarIdCharacteristicUUID = CBUUID(string: "85BF337C-5B64-48EB-A5F7-A9FED135C972")
    static let keepaliveCharacteristicUUID = CBUUID(string: "D802C645-5C7B-40DD-985A-9FBEE05FE85C")
    
    let advertismentDataLocalName = "Sonar"

    enum UnsentCharacteristicValue {
        case keepalive(value: Data)
        case identity(value: Data)
    }
    var unsentCharacteristicValue: UnsentCharacteristicValue?
    var keepaliveCharacteristic: CBMutableCharacteristic?
    var identityCharacteristic: CBMutableCharacteristic?
    
    var peripheral: CBPeripheralManager?
    
    let idGenerator: BroadcastIdGenerator
    
    init(idGenerator: BroadcastIdGenerator) {
        self.idGenerator = idGenerator
    }

    private func start() {
        guard let peripheral = peripheral else {
            assertionFailure("peripheral shouldn't be nil")
            return
        }
        guard peripheral.isAdvertising == false else {
            logger.error("peripheral manager already advertising, won't start again")
            return
        }

        let service = CBMutableService(type: ConcreteBTLEBroadcaster.sonarServiceUUID, primary: true)

        identityCharacteristic = CBMutableCharacteristic(
            type: ConcreteBTLEBroadcaster.sonarIdCharacteristicUUID,
            properties: CBCharacteristicProperties([.read, .notify]),
            value: nil,
            permissions: .readable)
        
        keepaliveCharacteristic = CBMutableCharacteristic(
            type: ConcreteBTLEBroadcaster.keepaliveCharacteristicUUID,
            properties: CBCharacteristicProperties([.notify]),
            value: nil,
            permissions: .readable)

        service.characteristics = [identityCharacteristic!, keepaliveCharacteristic!]
        peripheral.add(service)
    }

    func sendKeepalive(value: Data) {
        guard let peripheral = self.peripheral else {
            logger.info("peripheral shouldn't be nil")
            return
        }
        guard let keepaliveCharacteristic = self.keepaliveCharacteristic else {
            logger.info("keepaliveCharacteristic shouldn't be nil")
            return
        }
        
        self.unsentCharacteristicValue = .keepalive(value: value)
        let success = peripheral.updateValue(value, for: keepaliveCharacteristic, onSubscribedCentrals: nil)
        if success {
            logger.info("sent keepalive value: \(value.withUnsafeBytes { $0.load(as: UInt8.self) })")
            self.unsentCharacteristicValue = nil
        }
    }
    
    func updateIdentity() {
        guard let identityCharacteristic = self.identityCharacteristic else {
            // This "shouldn't happen" in normal course of the code, but if you start the
            // app with Bluetooth off and don't turn it on until registration is completed
            // you can get here.
            logger.info("identity characteristic not created yet")
            return
        }
        
        guard let ephemeralBroadcastId = idGenerator.broadcastIdentifier() else {
            assertionFailure("attempted to update identity without an identity")
            return
        }
        
        guard let peripheral = self.peripheral else {
            assertionFailure("peripheral shouldn't be nil")
            return
        }
        
        self.unsentCharacteristicValue = .identity(value: ephemeralBroadcastId)
        let success = peripheral.updateValue(ephemeralBroadcastId, for: identityCharacteristic, onSubscribedCentrals: nil)
        if success {
            logger.info("sent identity value \(ephemeralBroadcastId)")
            self.unsentCharacteristicValue = nil
        }
    }

    
    // MARK: - CBPeripheralManagerDelegate

    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
        guard let services = dict[CBPeripheralManagerRestoredStateServicesKey] as? [CBMutableService] else {
            logger.info("no services restored, creating from scratch...")
            return
        }
        for service in services {
            logger.info("restoring service \(service)")
            guard let characteristics = service.characteristics else {
                assertionFailure("service has no characteristics, this shouldn't happen")
                return
            }
            for characteristic in characteristics {
                if characteristic.uuid == ConcreteBTLEBroadcaster.keepaliveCharacteristicUUID {
                    logger.info("    retaining restored keepalive characteristic \(characteristic)")
                    self.keepaliveCharacteristic = (characteristic as! CBMutableCharacteristic)
                } else if characteristic.uuid == ConcreteBTLEBroadcaster.sonarIdCharacteristicUUID {
                    logger.info("    retaining restore identity characteristic \(characteristic)")
                    self.identityCharacteristic = (characteristic as! CBMutableCharacteristic)
                } else {
                    logger.info("    restored characteristic \(characteristic)")
                }
            }
        }
        if let advertismentData = dict[CBPeripheralManagerRestoredStateAdvertisementDataKey] as? [String: Any] {
            logger.info("restored advertisementData \(advertismentData)")
        }
        logger.info("peripheral manager \(peripheral.isAdvertising ? "is" : "is not") advertising")
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        logger.info("state: \(peripheral.state)")
        
        switch peripheral.state {
            
        case .poweredOn:
            self.peripheral = peripheral
            start()
            
        default:
            break
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        guard error == nil else {
            logger.info("error: \(error!))")
            return
        }
        
        logger.info("advertising identifier \(idGenerator.broadcastIdentifier()?.base64EncodedString() ??? "nil")")
        
        peripheral.startAdvertising([
            CBAdvertisementDataLocalNameKey: advertismentDataLocalName,
            CBAdvertisementDataServiceUUIDsKey: [service.uuid]
        ])
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        let characteristic: CBMutableCharacteristic
        let value: Data
        
        switch unsentCharacteristicValue {
        case nil:
            assertionFailure("\(#function) no data to update")
            return
            
        case .identity(let identityValue) where self.identityCharacteristic != nil:
            value = identityValue
            characteristic = self.identityCharacteristic!
            
        case .keepalive(let keepaliveValue) where self.keepaliveCharacteristic != nil:
            value = keepaliveValue
            characteristic = self.keepaliveCharacteristic!
            
        default:
            assertionFailure("shouldn't happen")
            return
        }
        
        let success = peripheral.updateValue(value, for: characteristic, onSubscribedCentrals: nil)
        if success {
            print("\(#function) re-sent value \(value)")
            self.unsentCharacteristicValue = nil
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        guard request.characteristic.uuid == ConcreteBTLEBroadcaster.sonarIdCharacteristicUUID else {
            logger.debug("received a read for unexpected characteristic \(request.characteristic.uuid.uuidString)")
            return
        }

        request.value = idGenerator.broadcastIdentifier()
        peripheral.respond(to: request, withResult: .success)
    }

    // MARK: - Healthcheck
    func isHealthy() -> Bool {
        guard peripheral != nil else { return false }
        guard identityCharacteristic != nil else { return false }
        guard keepaliveCharacteristic != nil else { return false }

        guard idGenerator.broadcastIdentifier() != nil else { return false }
        guard peripheral!.isAdvertising else { return false }
        guard peripheral!.state == .poweredOn else { return false }

        return true
    }
}

fileprivate let logger = Logger(label: "BTLE")
