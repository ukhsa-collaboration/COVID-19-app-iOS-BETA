//
//  BTLEListener.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CoreBluetooth

class BTLEListener: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var centralManager: CBCentralManager?
    
    let restoreIdentifier: String = "CoLocateCentralRestoreIdentifier"
    
    var peripheralManager: CBPeripheralManager?
    
    var peripheralList: [CBPeripheral] = []
    
    let inRangeperipherals: [CBPeripheral] = []
    
    var distanceManager = DistanceManager()
    var lastRssi: [String: NSNumber] = [:]
    var rangedDeviceIDs: [String] = []
    
    func start() {
        centralManager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionRestoreIdentifierKey: restoreIdentifier])
    }
    
    // MARK: CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("\(#file).\(#function)")
            
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
            
//            Comment this back in for testing if necessary, but be aware AllowDuplicates is ignored
//            ignored while running in the background, so we can't count on this behaviour
//            central.scanForPeripherals(withServices: [BTLEBroadcaster.primaryServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
            central.scanForPeripherals(withServices: [BTLEBroadcaster.coLocateServiceUUID])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("\(#file).\(#function) discovered peripheral: \(String(describing: peripheral.name))")
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
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("\(#file).\(#function) services = \(String(describing: peripheral.services))")
        
        // TODO: we're coalescing a bunch of error cases into one here, this might be confusing
        guard error == nil, peripheral.services?.count == 1, let primaryService = peripheral.services?.first else {
            print("\(#file).\(#function) no primary service found (error: \(String(describing: error))")
            return
        }
        peripheralList.append(peripheral)
        
        peripheral.discoverCharacteristics([BTLEBroadcaster.identityCharacteristicUUID], for: primaryService)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        //print("\(#file).\(#function) characteristics = \(String(describing: service.characteristics))")
        
        guard error == nil, let chars = service.characteristics else {return}

        // find our identity characteristic in the list—there'll be a continuity characteristic in the mix too
        for theChar in chars {
            if theChar.uuid == BTLEBroadcaster.identityCharacteristicUUID {
                peripheral.readValue(for: theChar)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
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

            doSomethingWithIdentityWeFound(data: data)
        }
            
    }

    // TODO: Indirect me through a "save the data service" protocol with a stub implementation which just does this log
    func doSomethingWithIdentityWeFound(data: Data) {
        let string = String(data: data, encoding: .utf8)!
        print("*** Contact event at \(Date()) with identity \(string)")
    }
    
}
