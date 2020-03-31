//
//  BTLEListener.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol BTLEListenerStateDelegate {
    func btleListener(_ listener: BTLEListener, didUpdateState state: CBManagerState)
}

class BTLEListener: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    var stateDelegate: BTLEListenerStateDelegate?
    var contactEventRecorder: ContactEventRecorder
    
    var centralManager: CBCentralManager?
    var peripheralManager: CBPeripheralManager?
    
    let restoreIdentifier: String = "CoLocateCentralRestoreIdentifier"

    var peripheralList: [CBPeripheral] = []
    let inRangeperipherals: [CBPeripheral] = []

    var lastRssi: [String: Int] = [:]

    init(contactEventRecorder: ContactEventRecorder = PlistContactEventRecorder.shared) {
        self.contactEventRecorder = contactEventRecorder
    }

    func start(stateDelegate: BTLEListenerStateDelegate?) {
        self.stateDelegate = stateDelegate

        guard centralManager == nil else { return }
        
        centralManager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionRestoreIdentifierKey: restoreIdentifier])
    }
    
    // MARK: CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        stateDelegate?.btleListener(self, didUpdateState: central.state)
        
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
            central.scanForPeripherals(withServices: [BTLEBroadcaster.sonarServiceUUID])
        @unknown default:
            fatalError()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("\(#file).\(#function) discovered peripheral: \(advertisementData)")
        
        lastRssi[peripheral.identifier.uuidString] = Int(truncating: RSSI)
        peripheralList.append(peripheral)
        centralManager?.connect(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("\(#file).\(#function) discovered peripheral: \(String(describing: peripheral.name))")
        
        peripheral.delegate = self
        peripheralList.append(peripheral)
        peripheral.discoverServices([BTLEBroadcaster.sonarServiceUUID])
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
        
        guard let sonarService = services.first(where: {$0.uuid == BTLEBroadcaster.sonarServiceUUID}) else {
            print("Sonar service not discovered for peripheral \(peripheral)")
            return
        }

        print("\(#file).\(#function) found sonarService: \(sonarService)")
        peripheral.discoverCharacteristics([BTLEBroadcaster.sonarIdCharacteristicUUID], for: sonarService)
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
        
        if let sonarIdCharacteristic = characteristics.first(where: {$0.uuid == BTLEBroadcaster.sonarIdCharacteristicUUID}) {
            print("\(#file).\(#function) found sonarIdCharacteristic: \(sonarIdCharacteristic)")
            peripheral.readValue(for: sonarIdCharacteristic)
        } else {
            print("Sonar Id characteristic not discovered for peripheral \(peripheral)")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Error updatingValueFor characteristic \(characteristic) : \(error!)")
            return
        }

        print("\(#file).\(#function) didUpdateValueFor characteristic: \(characteristic)")

        guard let data = characteristic.value else {
            print("\(#file).\(#function) No data found in characteristic.")
            return
        }

        guard characteristic.uuid == BTLEBroadcaster.sonarIdCharacteristicUUID else {
            return
        }

        recordContactWithIdentity(peripheral: peripheral, data: data)
    }

    func recordContactWithIdentity(peripheral: CBPeripheral, data: Data) {
        let uuidString = CBUUID(data: data).uuidString
        let uuid = UUID(uuidString: uuidString)!
        guard let rssi = lastRssi[peripheral.identifier.uuidString] else {
            print("Tried to record contact with \(peripheral.identifier.uuid) but there were no rssi values")
            return
        }

        print("recording a contact event at \(Date()) with rssi \(rssi)")

        let contactEvent = ContactEvent(remoteContactId: uuid, rssi: rssi)
        contactEventRecorder.record(contactEvent)
    }

}
