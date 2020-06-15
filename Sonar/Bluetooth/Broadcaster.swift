//
//  BTLEBroadcaster.swift
//  Sonar
//
//  Created by NHSX on 11/03/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import UIKit
import Logging

protocol Broadcaster {
    func sendKeepalive(value: Data)
    func updateIdentity()

    func isHealthy() -> Bool
}

class BTLEBroadcaster: NSObject, Broadcaster, SonarBTPeripheralManagerDelegate {

    let advertismentDataLocalName = "Sonar"

    enum UnsentCharacteristicValue {
        case keepalive(value: Data)
        case identity(value: Data)
    }
    var unsentCharacteristicValue: UnsentCharacteristicValue?
    var keepaliveCharacteristic: SonarBTCharacteristic?
    var identityCharacteristic: SonarBTCharacteristic?
    
    var peripheral: SonarBTPeripheralManager?
    
    let broadcastPayloadService: BroadcastPayloadService
    
    init(broadcastPayloadService: BroadcastPayloadService) {
        self.broadcastPayloadService = broadcastPayloadService
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

        let service = SonarBTService(type: Environment.sonarServiceUUID, primary: true)

        identityCharacteristic = SonarBTCharacteristic(
            type: Environment.sonarIdCharacteristicUUID,
            properties: SonarBTCharacteristicProperties([.read, .notify]),
            value: nil,
            permissions: .readable)
        
        keepaliveCharacteristic = SonarBTCharacteristic(
            type: Environment.keepaliveCharacteristicUUID,
            properties: SonarBTCharacteristicProperties([.notify]),
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
            // TODO: Why would this be nil?
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
        
        guard let broadcastPayload = broadcastPayloadService.broadcastPayload()?.data() else {
            // One way of getting to this point is when registration is nil in persistance and updateIdentity is called
            // which may be due to a 24 hour time period passing
            logger.warning("attempted to update identity without an identity")
            return
        }
        
        guard let peripheral = self.peripheral else {
            assertionFailure("peripheral shouldn't be nil")
            return
        }
        
        self.unsentCharacteristicValue = .identity(value: broadcastPayload)
        let success = peripheral.updateValue(broadcastPayload, for: identityCharacteristic, onSubscribedCentrals: nil)
        if success {
            logger.info("sent identity value \(PrintableBroadcastPayload(broadcastPayload))")
            self.unsentCharacteristicValue = nil
        }
    }

    
    // MARK: - CBPeripheralManagerDelegate

    func peripheralManager(_ peripheral: SonarBTPeripheralManager, willRestoreState dict: [String : Any]) {
        guard let services = dict[SonarBTPeripheralManagerRestoredStateServicesKey] as? [SonarBTService] else {
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
                if characteristic.uuid == Environment.keepaliveCharacteristicUUID {
                    logger.info("    retaining restored keepalive characteristic \(characteristic)")
                    self.keepaliveCharacteristic = characteristic
                } else if characteristic.uuid == Environment.sonarIdCharacteristicUUID {
                    logger.info("    retaining restored identity characteristic \(characteristic)")
                    self.identityCharacteristic = characteristic
                } else {
                    logger.info("    restored characteristic \(characteristic)")
                }
            }
        }
        if let advertismentData = dict[SonarBTPeripheralManagerRestoredStateAdvertisementDataKey] as? [String: Any] {
            logger.info("restored advertisementData \(advertismentData)")
        }
        logger.info("peripheral manager \(peripheral.isAdvertising ? "is" : "is not") advertising")
    }

    func peripheralManagerDidUpdateState(_ peripheral: SonarBTPeripheralManager) {
        logger.info("state: \(peripheral.state)")
        
        switch peripheral.state {
            
        case .poweredOn:
            self.peripheral = peripheral
            start()
            
        default:
            break
        }
    }
    
    func peripheralManager(_ peripheral: SonarBTPeripheralManager, didAdd service: SonarBTService, error: Error?) {
        guard error == nil else {
            logger.info("error: \(error!))")
            return
        }
        logger.info("starting advertising...")

        // Per #172564329 we don't want to expose this in release builds
        #if DEBUG || INTERNAL
        peripheral.startAdvertising([
            SonarBTAdvertisementDataLocalNameKey: advertismentDataLocalName,
            SonarBTAdvertisementDataServiceUUIDsKey: [service.uuid]
        ])
        #else
        peripheral.startAdvertising([
            SonarBTAdvertisementDataServiceUUIDsKey: [service.uuid]
        ])
        #endif
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: SonarBTPeripheralManager, error: Error?) {
        guard error == nil else {
            logger.info("error: \(error!))")
            return
        }

        if let data = broadcastPayloadService.broadcastPayload()?.data() {
            logger.info("advertising broadcast payload: \(PrintableBroadcastPayload(data))")
        } else {
            logger.info("advertising with no broadcast payload set")
        }
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: SonarBTPeripheralManager) {
        let characteristic: SonarBTCharacteristic
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
    
    func peripheralManager(_ peripheral: SonarBTPeripheralManager, central: SonarBTCentral, didSubscribeTo characteristic: SonarBTCharacteristic) {
        switch characteristic.uuid {
            
        case Environment.sonarIdCharacteristicUUID:
            logger.info("identity characteristic subscribed to by central \(central)")
            break
            
        case Environment.keepaliveCharacteristicUUID:
            logger.info("keepalive characteristic subscribed to by central \(central)")
            break
            
        default:
            logger.info("unknown characteristic \(characteristic) subscribed to by central \(central)")
        }
    }
    
    func peripheralManager(_ peripheral: SonarBTPeripheralManager, central: SonarBTCentral, didUnsubscribeFrom characteristic: SonarBTCharacteristic) {
        switch characteristic.uuid {
            
        case Environment.sonarIdCharacteristicUUID:
            logger.info("identity characteristic unsubscribed by central \(central)")
            break
            
        case Environment.keepaliveCharacteristicUUID:
            logger.info("keepalive characteristic unsubscribed by central \(central)")
            break
            
        default:
            logger.info("unknown characteristic \(characteristic) unsubscribed by central \(central)")
        }
    }
    
    func peripheralManager(_ peripheral: SonarBTPeripheralManager, didReceiveRead request: SonarBTATTRequest) {
        guard request.characteristic.uuid == Environment.sonarIdCharacteristicUUID else {
            logger.debug("received a read for unexpected characteristic \(request.characteristic.uuid.uuidString)")
            return
        }

        guard let broadcastPayload = broadcastPayloadService.broadcastPayload()?.data() else {
            logger.info("responding to read request with empty payload")
            request.value = Data()
            peripheral.respond(to: request, withResult: .success)
            return
        }
        
        logger.info("responding to read request with \(PrintableBroadcastPayload(broadcastPayload))")
        request.value = broadcastPayload
        peripheral.respond(to: request, withResult: .success)
    }
    
    // MARK: - Healthcheck
    func isHealthy() -> Bool {
        guard peripheral != nil else { return false }
        guard identityCharacteristic != nil else { return false }
        guard keepaliveCharacteristic != nil else { return false }

        guard broadcastPayloadService.broadcastPayload() != nil else { return false }
        guard peripheral!.isAdvertising else { return false }
        guard peripheral!.state == .poweredOn else { return false }

        return true
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
