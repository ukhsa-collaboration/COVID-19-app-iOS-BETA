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

protocol BTLEBroadcasterDelegate {
    func btleBroadcaster(_ broadcaster: BTLEBroadcaster, didUpdateState state: CBManagerState)
}

class BTLEBroadcaster: NSObject, CBPeripheralManagerDelegate {
    
    static let sonarServiceUUID = CBUUID(nsuuid: UUID(uuidString: "c1f5983c-fa94-4ac8-8e2e-bb86d6de9b21")!)
    static let sonarIdCharacteristicUUID = CBUUID(nsuuid: UUID(uuidString: "85BF337C-5B64-48EB-A5F7-A9FED135C972")!)

    var sonarId: CBUUID?
    var primaryService: CBService?
    var state: CBManagerState = .unknown
    var delegate: BTLEBroadcasterDelegate?
    var peripheralManager: CBPeripheralManager?

    let restoreIdentifier: String = "CoLocatePeripheralRestoreIdentifier"
    
    func start(delegate: BTLEBroadcasterDelegate?) {
        self.delegate = delegate
        
        peripheralManager = CBPeripheralManager(
            delegate: self,
            queue: nil,
            options: [CBPeripheralManagerOptionRestoreIdentifierKey: restoreIdentifier])
    }
    
    func setSonarUUID(_ uuid: UUID) {
        guard state == .poweredOn else { return }

        sonarId = CBUUID(nsuuid: uuid)
        startBroadcasting()
    }

    fileprivate func startBroadcasting() {
        guard let sonarId = sonarId else { return }

        let service = CBMutableService(type: BTLEBroadcaster.sonarServiceUUID, primary: true)

        let identityCharacteristic = CBMutableCharacteristic(type: BTLEBroadcaster.sonarIdCharacteristicUUID, properties: CBCharacteristicProperties([.read]), value: sonarId.data, permissions: .readable)

        service.characteristics = [identityCharacteristic]
        peripheralManager?.add(service)
    }

    // MARK: CBPeripheralManagerDelegate

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        delegate?.btleBroadcaster(self, didUpdateState: peripheral.state)


        state = peripheral.state

        switch (peripheral.state) {
            
        case .unknown:
            print("\(#file).\(#function) .unknown")
            
        case .resetting:
            print("\(#file).\(#function) .resetting")
            
        case .unsupported:
            print("\(#file).\(#function) .unsupported")
            
        case .unauthorized:
            print("\(#file).\(#function) .unauthorized")
            
        case .poweredOff:
            print("\(#file).\(#function) .poweredOff")
            
        case .poweredOn:
            print("\(#file).\(#function) .poweredOn")

            if (sonarId != nil) {
                startBroadcasting();
            }
            
        @unknown default:
            fatalError()
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        guard error == nil else {
            print("\(#file).\(#function) error: \(error!))")
            return
        }
        
        print("\(#file).\(#function) service: \(service)")
        self.primaryService = service
        
        print("\(#file).\(#function) advertising device identifier \(String(describing: sonarId?.uuidString))")
        peripheralManager?.startAdvertising([
            CBAdvertisementDataLocalNameKey: "CoLocate",
            CBAdvertisementDataServiceUUIDsKey: [service.uuid]
        ])
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
        print("\(#file).\(#function)")

        self.peripheralManager = peripheral
        if let services = dict[CBPeripheralManagerRestoredStateServicesKey] as? [CBMutableService], let primaryService = services.first {
            self.primaryService = primaryService
        } else {
            print("\(#file).\(#function) No services to restore!")
        }
    }

}
