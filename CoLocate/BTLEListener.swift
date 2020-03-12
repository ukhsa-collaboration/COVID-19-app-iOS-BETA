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
    
    let inRangeperipherals: [CBPeripheral] = []
    
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
            
            central.scanForPeripherals(withServices: [BTLEBroadcaster.primaryServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("\(#file).\(#function) discovered peripheral: \(String(describing: peripheral.name))")
        print("\(#file).\(#function) discovered peripheral: \(advertisementData)")
        
//        central.connect(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("\(#file).\(#function) discovered peripheral: \(String(describing: peripheral.name))")
        
        peripheral.delegate = self
        peripheral.discoverServices([BTLEBroadcaster.primaryServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        print("\(#file).\(#function) got centralManager: \(central)")
        self.centralManager = central
    }
    
    
    // MARK: CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("\(#file).\(#function) services = \(String(describing: peripheral.services))")
        
        guard error == nil, let primaryService = peripheral.services?.first else {
            print("\(#file).\(#function) no primary service found (error: \(String(describing: error))")
            return
        }
        peripheral.discoverCharacteristics([BTLEBroadcaster.identityCharacteristicUUID], for: primaryService)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("\(#file).\(#function) characteristics = \(String(describing: service.characteristics))")
        
        guard error == nil, let identityCharacteristic = service.characteristics?.first else {
            print("\(#file).\(#function) no identity characteristic found (error: \(String(describing: error))")
            return
        }
        
        
        if let value = identityCharacteristic.value {
            doSomethingWithIdentityWeFound(data: value)
        } else {
            print("\(#file).\(#function) no value found for identity characteristic")
        }
    }
    
    // TODO: Indirect me through a "save the data service" protocol with a stub implementation which just does this log
    func doSomethingWithIdentityWeFound(data: Data) {
        let string = String(data: data, encoding: .utf8)!
        print("Contact event at \(Date()) with identity \(string)")
    }
    
}
