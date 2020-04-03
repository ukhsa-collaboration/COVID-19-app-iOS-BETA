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
    func start(stateDelegate: BTLEBroadcasterStateDelegate?)
    func setSonarUUID(_ uuid: UUID)
}

class ConcreteBTLEBroadcaster: NSObject, BTLEBroadcaster, CBPeripheralManagerDelegate {
    
    static let sonarServiceUUID = CBUUID(nsuuid: UUID(uuidString: "c1f5983c-fa94-4ac8-8e2e-bb86d6de9b21")!)
    static let sonarIdCharacteristicUUID = CBUUID(nsuuid: UUID(uuidString: "85BF337C-5B64-48EB-A5F7-A9FED135C972")!)

    let logger = Logger(label: "BTLEBroadcaster")
    
    var sonarId: CBUUID?
    var primaryService: CBService? // TODO: should be sonarIdService
    var state: CBManagerState = .unknown
    var stateDelegate: BTLEBroadcasterStateDelegate?
    var peripheralManager: CBPeripheralManager?

    let restoreIdentifier: String = "SonarPeripheralRestoreIdentifier"
    
    func start(stateDelegate: BTLEBroadcasterStateDelegate?) {
        self.stateDelegate = stateDelegate

        guard peripheralManager == nil else { return }
        
        peripheralManager = CBPeripheralManager(
            delegate: self,
            queue: nil,
            options: [CBPeripheralManagerOptionRestoreIdentifierKey: restoreIdentifier])
    }
    
    func setSonarUUID(_ uuid: UUID) {
        sonarId = CBUUID(nsuuid: uuid)

        startBroadcasting()
    }

    fileprivate func startBroadcasting() {
        guard state == .poweredOn, let sonarId = sonarId else { return }

        let service = CBMutableService(type: ConcreteBTLEBroadcaster.sonarServiceUUID, primary: true)

        let identityCharacteristic = CBMutableCharacteristic(type: ConcreteBTLEBroadcaster.sonarIdCharacteristicUUID, properties: CBCharacteristicProperties([.read]), value: sonarId.data, permissions: .readable)

        service.characteristics = [identityCharacteristic]
        peripheralManager?.add(service)
    }

    // MARK: CBPeripheralManagerDelegate

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        logger.info("state: \(peripheral.state)")
        
        stateDelegate?.btleBroadcaster(self, didUpdateState: peripheral.state)

        state = peripheral.state

        switch (peripheral.state) {
            
        case .poweredOn:
            startBroadcasting();
            
        default:
            break
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        guard error == nil else {
            logger.info("error: \(error!))")
            return
        }
        
        logger.info("\(service)")
        self.primaryService = service
        
        logger.info("now advertising sonarId \(sonarId?.uuidString ?? "nil")")
        
        peripheralManager?.startAdvertising([
            CBAdvertisementDataLocalNameKey: "CoLocate",
            CBAdvertisementDataServiceUUIDsKey: [service.uuid]
        ])
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
        self.peripheralManager = peripheral
        if let services = dict[CBPeripheralManagerRestoredStateServicesKey] as? [CBMutableService], let primaryService = services.first {
            self.primaryService = primaryService
        } else {
            logger.info("No services to restore!")
        }
    }

}
