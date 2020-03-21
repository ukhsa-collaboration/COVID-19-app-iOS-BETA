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
    
    static let coLocateServiceUUID = CBUUID(nsuuid: UUID(uuidString: "c1f5983c-fa94-4ac8-8e2e-bb86d6de9b21")!)
    static let deviceIdentifierCharacteristicUUID = CBUUID(nsuuid: UUID(uuidString: "85BF337C-5B64-48EB-A5F7-A9FED135C972")!)

    // This is safe to force-unwrap in the vast majority of cases
    // according to the docs this will only be nil
    //     after a device has been rebooted
    //     and the app is running before the device has been unlocked
    var deviceIdentifier = CBUUID(nsuuid: UIDevice.current.identifierForVendor!)

    var primaryService: CBService?
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
    
    // MARK: CBPeripheralManagerDelegate
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        delegate?.btleBroadcaster(self, didUpdateState: peripheral.state)
        
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
         
            let service = CBMutableService(type: BTLEBroadcaster.coLocateServiceUUID, primary: true)
            
            let identityCharacteristic = CBMutableCharacteristic(type: BTLEBroadcaster.deviceIdentifierCharacteristicUUID, properties: CBCharacteristicProperties([.read]), value: deviceIdentifier.data, permissions: .readable)
            
            service.characteristics = [identityCharacteristic]
            peripheralManager?.add(service)
        @unknown default:
            fatalError()
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        guard error == nil else {
            print("\(#file).\(#function) error: \(String(describing: error))")
            return
        }
        
        print("\(#file).\(#function) service: \(service)")
        self.primaryService = service
        
        print("\(#file).\(#function) advertising device identifier \(deviceIdentifier.uuidString)")
        peripheralManager?.startAdvertising([
            CBAdvertisementDataLocalNameKey: "CoLocate",
            CBAdvertisementDataServiceUUIDsKey: [service.uuid]
        ])
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
        print("\(#file).\(#function)")

        self.peripheralManager = peripheral
        if let services = dict[CBPeripheralManagerRestoredStateServicesKey] as? [CBMutableService] {
            self.primaryService = serviceMatchingOurUUID(services)
        } else {
            print("\(#file).\(#function) No services to restore!")
        }
    }

    private func serviceMatchingOurUUID(_ services: [CBMutableService]) -> CBMutableService? {
        if let matching = services.first(where: {
                $0.characteristics?
                    .map({ (characteristic) -> CBUUID  in characteristic.uuid })
                    .contains(BTLEBroadcaster.deviceIdentifierCharacteristicUUID) ?? false
        }) {
            return matching
        } else {
            print("\(#file).\(#function) No service matching our characteristic uuid to restore!")
            return nil
        }
    }
}
