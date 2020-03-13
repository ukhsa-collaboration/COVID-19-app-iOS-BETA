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
    
    static let primaryServiceUUID = CBUUID(nsuuid: UUID(uuidString: "c1f5983c-fa94-4ac8-8e2e-bb86d6de9b21")!)
    var deviceUUID:CBUUID? // TODO REPLACE THIS WITH A UNIQUE ID FROM SOMEWHERE UNIQUE TO THIS DEVICE (SERVER GENERATED)
    static let identityCharacteristicUUID = CBUUID(nsuuid: UUID(uuidString: "85BF337C-5B64-48EB-A5F7-A9FED135C972")!)

    var primaryService: CBService?
    
    let restoreIdentifier: String = "CoLocatePeripheralRestoreIdentifier"
    
    var peripheralManager: CBPeripheralManager?
    
    var peripheral: CBPeripheral?
    
    init(deviceID: UUID) {
        deviceUUID = CBUUID(nsuuid: deviceID)
    }
    
    func start() {
        peripheralManager = CBPeripheralManager(
            delegate: self,
            queue: nil,
            options: [CBPeripheralManagerOptionRestoreIdentifierKey: restoreIdentifier])
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
         
            print("DEVICE ID: " + self.deviceUUID!.uuidString)
            let service = CBMutableService(type: deviceUUID!, primary: true)
            var idChar = CBMutableCharacteristic(type: deviceUUID!, properties: CBCharacteristicProperties([CBCharacteristicProperties.read]), value: UUID().uuidString.data(using: .utf8), permissions: .readable)
            //idChar.descriptors = [
            //    CBMutableDescriptor(type: BTLEBroadcaster.identityCharacteristicUUID,value:"uk.nhs.colocate.deviceID".data(using: .utf8))
            //]
            //var idValueChar = CBMutableCharacteristic(type: BTLEBroadcaster.primaryServiceUUID, properties: CBCharacteristicProperties([CBCharacteristicProperties.read]), value: BTLEBroadcaster.primaryServiceUUID.uuidString.data(using: .utf8), permissions: .readable)
            //idValueChar.descriptors = [
            //    CBMutableDescriptor(type: BTLEBroadcaster.primaryServiceUUID, value:"uk.nhs.colocate.deviceID".data(using: .utf8))
            //]
            service.characteristics = [idChar]
            print("CHARAC LENGTH: \(service.characteristics?.count)")
            peripheralManager?.add(service)
            //let service2 = CBMutableService(type: BTLEBroadcaster.primaryServiceUUID, primary: true)
            //peripheralManager?.add(service2)
            // cannot add two services, even primary - only apple devices can do that
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
    
    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
        print("\(#file).\(#function)")

        self.peripheralManager = peripheral
        if let services = dict[CBPeripheralManagerRestoredStateServicesKey] as? [CBMutableService] {
            self.primaryService = services.first
        } else {
            print("\(#file).\(#function) No services to restore!")
        }
    }
    
}
