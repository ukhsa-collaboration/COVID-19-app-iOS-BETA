//
//  BTLEBroadcaster.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CoreBluetooth

class BTLEBroadcaster: NSObject, CBPeripheralManagerDelegate {
    
    let primaryServiceUUID = CBUUID(nsuuid: UUID(uuidString: "c1f5983c-fa94-4ac8-8e2e-bb86d6de9b21")!)
    
    var primaryService: CBService?
    
    let restoreIdentifier: String = "restoreIdentifier"
    
    var peripheralManager: CBPeripheralManager?
    
    var peripheral: CBPeripheral?
    
    func doStuff() {
        peripheralManager = CBPeripheralManager(
            delegate: self,
            queue: nil,
        //    options: [CBPeripheralManagerOptionRestoreIdentifierKey: restoreIdentifier])
            options: [:])
    }
    
    // MARK: CBPeripheralManagerDelegate
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("\(#file).\(#function)")
        
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
         
            let service = CBMutableService(type: primaryServiceUUID, primary: true)
            peripheralManager?.add(service)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        print("\(#file).\(#function)")
        guard error == nil else {
            print("\(#file).\(#function) error: \(String(describing: error))")
            return
        }
        
        self.primaryService = service
        peripheralManager?.startAdvertising([
            CBAdvertisementDataLocalNameKey: "CoLocate",
            CBAdvertisementDataServiceUUIDsKey: [service.uuid]
        ])
    }
    
//    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
//        print("\(#file).\(#function)")
//
//        self.peripheralManager = peripheral
//        if let services = dict[CBPeripheralManagerRestoredStateServicesKey] as? [CBMutableService] {
//            self.primaryService = services.first
//        } else {
//            print("\(#file).\(#function) No services to restore!")
//        }
//    }
    
}
