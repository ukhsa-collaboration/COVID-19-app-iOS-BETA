//
//  BTLEListener.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol BTLEListenerDelegate {
    func btleListener(_ listener: BTLEListener, didUpdateState state: CBManagerState)
}

class BTLEListener: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var delegate: BTLEListenerDelegate?
    var contactEventService: ContactEventService! // Should this be in the init instead of start?
    
    var centralManager: CBCentralManager?
    
    let restoreIdentifier: String = "CoLocateCentralRestoreIdentifier"
    
    var peripheralManager: CBPeripheralManager?
    
    var peripheralList: [CBPeripheral] = []
    
    let inRangeperipherals: [CBPeripheral] = []
    
    var distanceManager = DistanceManager()
    var lastRssi: [String: NSNumber] = [:]
    var rangedDeviceIDs: [String] = []
    
    func start(delegate: BTLEListenerDelegate?, contactEventService: ContactEventService = ContactEventService()) {
        self.delegate = delegate
        self.contactEventService = contactEventService
        
        centralManager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionRestoreIdentifierKey: restoreIdentifier])
    }
    
    // MARK: CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        delegate?.btleListener(self, didUpdateState: central.state)
        
        switch (central.state) {
                
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
            
//            Comment this back in for testing if necessary, but be aware AllowDuplicates is
//            ignored while running in the background, so we can't count on this behaviour
//            central.scanForPeripherals(withServices: [BTLEBroadcaster.primaryServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
            central.scanForPeripherals(withServices: [BTLEBroadcaster.coLocateServiceUUID])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("\(#file).\(#function) discovered peripheral: \(advertisementData)")
        
        lastRssi[peripheral.identifier.uuidString] = RSSI
        peripheralList.append(peripheral)
        centralManager?.connect(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("\(#file).\(#function) discovered peripheral: \(String(describing: peripheral.name))")
        
        peripheral.delegate = self
        peripheralList.append(peripheral)
        peripheral.discoverServices([BTLEBroadcaster.coLocateServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        print("\(#file).\(#function) got centralManager: \(central)")
        
        self.centralManager = central
    }
    
    // MARK: CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        print("\(#file).\(#function) peripheral \(peripheral) invalidating services:\n")
        for service in invalidatedServices {
            print("\(#file).\(#function)     \(service):\n")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("Error discovering services: \(error!)")
            return
        }
        
        guard let services = peripheral.services, services.count > 0 else {
            print("No services discovered for peripheral \(peripheral)")
            return
        }

        if let coLocateService = services.first(where: {$0.uuid == BTLEBroadcaster.coLocateServiceUUID}) {
            print("\(#file).\(#function) found coLocateService: \(coLocateService)")
            peripheral.discoverCharacteristics([BTLEBroadcaster.deviceIdentifierCharacteristicUUID], for: coLocateService)
        } else {
            print("CoLocate service not discovered for peripheral \(peripheral)")
        }
        
        // TODO: Do we really need to save this peripheral here? It gets passed to us on every delegate callback
        //peripheralList.append(peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("Error discovering characteristics: \(error!)")
            return
        }
        
        guard let characteristics = service.characteristics, characteristics.count > 0 else {
            print("No characteristics discovered for service \(service)")
            return
        }
        
        if let deviceIdCharacteristic = characteristics.first(where: {$0.uuid == BTLEBroadcaster.deviceIdentifierCharacteristicUUID}) {
            print("\(#file).\(#function) found deviceIdCharacteristic: \(deviceIdCharacteristic)")
            peripheral.readValue(for: deviceIdCharacteristic)
        } else {
            print("Device identity characteristic not discovered for peripheral \(peripheral)")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("\(#file).\(#function) characteristic: \(characteristic)")

        if let data = characteristic.value {
//            let pid = peripheral.identifier.uuidString
//            if (lastRssi.keys.contains(pid)) {
//                let rssi = Int(truncating: lastRssi[pid]!)
//                print("    Adding distance for deviceID: " + value + " rssi: \(rssi)")
//                distanceManager.addDistance(remoteID: service.uuid.uuidString, rssi: rssi)
//                //lastRssi.removeValue(forKey: pid)
//                rangedDeviceIDs.append(service.uuid.uuidString)
//
//
//            let uid = String(describing: characteristic.uuid)
//            if let val = characteristic.value {
//                let fval = String(describing: val)
//                print("    CHAR VALUE: peripheral id: " + peripheral.identifier.uuidString + " characteristic: " + uid + " value: " + fval)
//            }

            if characteristic.uuid == BTLEBroadcaster.deviceIdentifierCharacteristicUUID {
                doSomethingWithIdentityWeFound(data: data)                
            }
        }
            
    }

    func doSomethingWithIdentityWeFound(data: Data) {
        let uuidString = CBUUID(data: data).uuidString
        let uuid = UUID(uuidString: uuidString)!
        let contactEvent = ContactEvent(uuid: uuid)
        contactEventService.record(contactEvent)
    }
    
}
