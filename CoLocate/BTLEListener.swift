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
    
    var peripheralList = Array<CBPeripheral>()
    
    let inRangeperipherals: [CBPeripheral] = []
    
    var distanceManager = DistanceManager()
    var lastRssi = Dictionary<String,NSNumber>()
    var rangedDeviceIDs = Array<String>()
    
    func start() {
        centralManager = CBCentralManager(
            delegate: self,
            queue: DispatchQueue.global(),
            options: [CBCentralManagerOptionRestoreIdentifierKey: restoreIdentifier])
        //peripheralManager = CBPeripheralManager(delegate: self as? CBPeripheralManagerDelegate, queue: DispatchQueue.global())
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
            
            central.scanForPeripherals(withServices: [], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //print("\(#file).\(#function) discovered peripheral: \(String(describing: peripheral.name))")
        //print("\(#file).\(#function) discovered peripheral: \(advertisementData)")
        
        //if let svc = advertisementData.first {
        var gotValidID = false
        for svc in advertisementData {
            //print("GOT FIRST ADVERT")
            //print("ADVERTISED SERVICE INSTANCE: " + String(describing: svc.value) + " of type: " + String(describing: type(of: svc.value)))
            if let idArray = svc.value as? NSMutableArray {
                // either a mutable array of UUIDs (E.g. custom app) or a single number (E.g. heart monitor)
                //print("GOT NSMUTABLEARRAY")
                //if let firstId = idArray.firstObject {
                    //print(idArray)
                    //print("ADVERTISED SVC ID: " + String(describing: firstId) + " of type: " + String(describing: type(of:firstId)))
                    // ONLY THE PRIMARY IS SHOWN AT THIS POINT
                    for id in idArray {
                        print("   SVC ID: " + String(describing: id))
                        lastRssi[String(describing: id)] = RSSI
                        gotValidID = true
                    }
                    //if (String(describing: firstId) == BTLEBroadcaster.primaryServiceUUID.uuidString) {
                    //}

                    //peripheral.discoverCharacteristics(nil, for: UUID(uuidString: String(describing: firstId)))
                //}
            }
        }
        if (gotValidID) {
            //print("Valid service ID. Connecting to peripheral")
            peripheralList.append(peripheral)
            centralManager?.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        //print("\(#file).\(#function) discovered peripheral: \(String(describing: peripheral.name))")
        
        peripheral.delegate = self
        //peripheral.discoverServices(nil)
        peripheralList.append(peripheral)
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        print("\(#file).\(#function) got centralManager: \(central)")
        self.centralManager = central
    }
    
    
    // MARK: CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        //print("\(#file).\(#function) services = \(String(describing: peripheral.services))")
        
        guard error == nil, let primaryService = peripheral.services?.first else {
            print("\(#file).\(#function) no primary service found (error: \(String(describing: error))")
            return
        }
        peripheralList.append(peripheral)
        for svc in peripheral.services! {
            peripheral.discoverCharacteristics([BTLEBroadcaster.primaryServiceUUID], for: svc)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        //print("\(#file).\(#function) characteristics = \(String(describing: service.characteristics))")
        
        guard error == nil, let chars = service.characteristics else {return}
        
        for theChar in chars {
            //print("GOT CHAR!")
            if String(describing: theChar.uuid) != "Continuity" {
                //print("    characteristic uuid: " + String(describing: theChar.uuid))
                if theChar.uuid.uuidString == BTLEBroadcaster.primaryServiceUUID.uuidString {
                    // characteristic ID is the device ID
                    //print("    CONTACT!!! " + theChar.uuid.uuidString)
                    let svcid = service.uuid.uuidString
                    if (lastRssi.keys.contains(svcid)) {
                        let rssi = Int(truncating: lastRssi[service.uuid.uuidString]!)
                        print("    Adding distance for remoteDeviceID: " + service.uuid.uuidString + " rssi: \(rssi)")
                        distanceManager.addDistance(remoteID: service.uuid.uuidString,rssi: rssi)
                        lastRssi.removeValue(forKey: service.uuid.uuidString)
                        rangedDeviceIDs.append(service.uuid.uuidString)
                    }
                }
            }
            //print(String(describing: theChar.value))
            //if theChar.uuid.uuidString == BTLEBroadcaster.identityCharacteristicUUID.uuidString {
                // must be a uuid
            //    if let value = theChar.value {
            //        doSomethingWithIdentityWeFound(data: value)
            //    }
            //}
            /*
            if let descs = theChar.descriptors {
                for desc in descs {
                    if let data = desc.value {
                        print("DESCRIPTOR DATA:-")
                        print(data)
                        if let dat = data as? Data {
                            if (String(data: dat, encoding: .utf8) == "uk.nhs.colocate.deviceID") {
                                // value is a deviceID
                                if let value = theChar.value {
                                    doSomethingWithIdentityWeFound(data: value)
                                }
                            }
                        }
                    }
                }
            }
 */
        }
        // Now release the connection???
        
        /*
        guard error == nil, let identityCharacteristic = service.characteristics?.first else {
            print("\(#file).\(#function) no identity characteristic found (error: \(String(describing: error))")
            return
        }
        
        
        if let value = identityCharacteristic.value {
            doSomethingWithIdentityWeFound(data: value)
        } else {
            print("\(#file).\(#function) no value found for identity characteristic")
        }
 */
    }
    
    // TODO: Indirect me through a "save the data service" protocol with a stub implementation which just does this log
    func doSomethingWithIdentityWeFound(data: Data) {
        let string = String(data: data, encoding: .utf8)!
        print("*** Contact event at \(Date()) with identity \(string)")
    }
    
}
