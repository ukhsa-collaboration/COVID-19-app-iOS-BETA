//
//  BTLEBroadcaster.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit
import Logging

protocol BTLEBroadcasterStateDelegate {
    func btleBroadcaster(_ broadcaster: BTLEBroadcaster, didUpdateState state: CBManagerState)
}

protocol BTLEBroadcaster {
    func start()
}

class ConcreteBTLEBroadcaster: NSObject, BTLEBroadcaster, CBPeripheralManagerDelegate {
    
    static let sonarServiceUUID = CBUUID(string: "c1f5983c-fa94-4ac8-8e2e-bb86d6de9b21")
    static let sonarIdCharacteristicUUID = CBUUID(string: "85BF337C-5B64-48EB-A5F7-A9FED135C972")
    static let keepaliveCharacteristicUUID = CBUUID(string: "D802C645-5C7B-40DD-985A-9FBEE05FE85C")

    var peripheral: CBPeripheralManager?
    var keepaliveCharacteristic: CBMutableCharacteristic?
    var keepaliveValue: Data?
    var stateDelegate: BTLEBroadcasterStateDelegate?
    let idGenerator: BroadcastIdGenerator
    
    init(idGenerator: BroadcastIdGenerator) {
        self.idGenerator = idGenerator
    }

    func start() {
        guard let peripheral = peripheral else {
            logger.error("peripheral is nil, this shouldn't happen")
            return
        }
        guard peripheral.isAdvertising == false else {
            logger.error("peripheral manager already advertising, won't start again")
            return
        }
        guard let identifier = idGenerator.broadcastIdentifier() else {
            logger.error("no broadcastIdentifier available, will not start broadcasting")
            return
        }

        let service = CBMutableService(type: ConcreteBTLEBroadcaster.sonarServiceUUID, primary: true)

        let identityCharacteristic = CBMutableCharacteristic(
            type: ConcreteBTLEBroadcaster.sonarIdCharacteristicUUID,
            properties: CBCharacteristicProperties([.read]),
            value: identifier,
            permissions: .readable)
        
        keepaliveCharacteristic = CBMutableCharacteristic(
            type: ConcreteBTLEBroadcaster.keepaliveCharacteristicUUID,
            properties: CBCharacteristicProperties([.notify]),
            value: nil,
            permissions: .readable)

        service.characteristics = [identityCharacteristic, keepaliveCharacteristic!]
        peripheral.add(service)
    }

    func sendKeepalive(value: Data) {
        guard let peripheral = self.peripheral else {
            assertionFailure("peripheral shouldn't be nil")
            return
        }
        guard let keepaliveCharacteristic = self.keepaliveCharacteristic else {
            assertionFailure("keepaliveCharacteristic shouldn't be nil")
            return
        }
        
        self.keepaliveValue = value
        let success = peripheral.updateValue(value, for: keepaliveCharacteristic, onSubscribedCentrals: nil)
        if success {
            logger.info("sent keepalive value \(value)")
            self.keepaliveValue = nil
        }
    }

    
    // MARK: - CBPeripheralManagerDelegate

    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
        guard let services = dict[CBPeripheralManagerRestoredStateServicesKey] as? [CBMutableService],
              let sonarIdService = services.first else {
            logger.info("No services to restore!")
            return
        }

        logger.info("restoring \(sonarIdService)")
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        logger.info("state: \(peripheral.state)")
        
        stateDelegate?.btleBroadcaster(self, didUpdateState: peripheral.state)

        switch (peripheral.state) {
            
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
            CBAdvertisementDataLocalNameKey: "Sonar",
            CBAdvertisementDataServiceUUIDsKey: [service.uuid]
        ])
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        guard let keepaliveCharacteristic = self.keepaliveCharacteristic else {
            assertionFailure("keepaliveCharacteristic shouldn't be nil")
            return
        }
        guard let value = self.keepaliveValue else {
            assertionFailure("no value to send")
            return
        }
        
        let success = peripheral.updateValue(value, for: keepaliveCharacteristic, onSubscribedCentrals: nil)
        if success {
            logger.info("re-sent keepalive value \(value)")
            self.keepaliveValue = nil
        }
    }
    
}

fileprivate let logger = Logger(label: "BTLE")
