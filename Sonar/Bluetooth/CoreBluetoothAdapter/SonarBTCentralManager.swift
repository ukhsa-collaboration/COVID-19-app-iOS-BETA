//
//  CBManagerAdapter.swift
//  Sonar
//
//  Created by NHSX on 16/6/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol SonarBTCentralManagerDelegate: class {
    func centralManagerDidUpdateState(_ central: SonarBTCentralManager)
    func centralManager(_ central: SonarBTCentralManager, willRestoreState dict: [String : Any])
    func centralManager(_ central: SonarBTCentralManager, didConnect peripheral: SonarBTPeripheral)
    func centralManager(_ central: SonarBTCentralManager, didFailToConnect peripheral: SonarBTPeripheral, error: Error?)
    func centralManager(_ central: SonarBTCentralManager, didDisconnectPeripheral peripheral: SonarBTPeripheral, error: Error?)
    func centralManager(_ central: SonarBTCentralManager, didDiscover peripheral: SonarBTPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
    func centralManager(_ central: SonarBTCentralManager, connectionEventDidOccur event: SonarBTConnectionEvent, for peripheral: SonarBTPeripheral)
}

public let SonarBTCentralManagerOptionShowPowerAlertKey = CBCentralManagerOptionShowPowerAlertKey
public let SonarBTCentralManagerOptionRestoreIdentifierKey = CBCentralManagerOptionRestoreIdentifierKey
public let SonarBTCentralManagerScanOptionAllowDuplicatesKey = CBCentralManagerScanOptionAllowDuplicatesKey
public let SonarBTCentralManagerScanOptionSolicitedServiceUUIDsKey = CBCentralManagerScanOptionSolicitedServiceUUIDsKey
public let SonarBTConnectPeripheralOptionNotifyOnConnectionKey = CBConnectPeripheralOptionNotifyOnConnectionKey
public let SonarBTConnectPeripheralOptionNotifyOnDisconnectionKey = CBConnectPeripheralOptionNotifyOnDisconnectionKey
public let SonarBTConnectPeripheralOptionNotifyOnNotificationKey = CBConnectPeripheralOptionNotifyOnNotificationKey
public let SonarBTConnectPeripheralOptionStartDelayKey = CBConnectPeripheralOptionStartDelayKey
@available(iOS 13.0, *)
public let SonarBTConnectPeripheralOptionEnableTransportBridgingKey = CBConnectPeripheralOptionEnableTransportBridgingKey
@available(iOS 13.0, *)
public let SonarBTConnectPeripheralOptionRequiresANCS = CBConnectPeripheralOptionRequiresANCS
public let SonarBTCentralManagerRestoredStatePeripheralsKey = CBCentralManagerRestoredStatePeripheralsKey
public let SonarBTCentralManagerRestoredStateScanServicesKey = CBCentralManagerRestoredStateScanServicesKey
public let SonarBTCentralManagerRestoredStateScanOptionsKey = CBCentralManagerRestoredStateScanOptionsKey

typealias SonarBTManagerState = CBManagerState
class SonarBTCentralManager: NSObject {
    private var cbManager: CBCentralManager!
    weak var delegate: SonarBTCentralManagerDelegate?
    weak var peripheralDelegate: SonarBTPeripheralDelegate?
    
    public init(delegate: SonarBTCentralManagerDelegate?, peripheralDelegate: SonarBTPeripheralDelegate?, queue: DispatchQueue?, options: [String : Any]? = nil) {
        self.delegate = delegate
        self.peripheralDelegate = peripheralDelegate
        super.init()
        
        self.cbManager = CBCentralManager(delegate: self, queue: queue, options: options)
    }
    
    var state: SonarBTManagerState {
        return cbManager.state
    }
    
    var isScanning: Bool {
        return cbManager.isScanning
    }
    
    func cancelPeripheralConnection(_ peripheral: SonarBTPeripheral) {
        cbManager.cancelPeripheralConnection(peripheral.unwrap)
    }
    
    func scanForPeripherals(withServices serviceUUIDs: [SonarBTUUID]?, options: [String : Any]? = nil) {
        cbManager.scanForPeripherals(withServices: serviceUUIDs, options: options)
    }
    
    func connect(_ peripheral: SonarBTPeripheral, options: [String : Any]? = nil) {
        cbManager.connect(peripheral.unwrap, options: options)
    }
}

extension SonarBTCentralManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        delegate?.centralManagerDidUpdateState(self)
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        delegate?.centralManager(self, willRestoreState: wrapState(dict))
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        delegate?.centralManager(self, didConnect: SonarBTPeripheral.wrapperFor(peripheral, delegate: peripheralDelegate))
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        delegate?.centralManager(self, didFailToConnect: SonarBTPeripheral.wrapperFor(peripheral, delegate: peripheralDelegate), error: error)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        delegate?.centralManager(self, didDisconnectPeripheral: SonarBTPeripheral.wrapperFor(peripheral, delegate: peripheralDelegate), error: error)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        delegate?.centralManager(self, didDiscover: SonarBTPeripheral.wrapperFor(peripheral, delegate: peripheralDelegate), advertisementData: advertisementData, rssi: RSSI)
    }
    
    func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral) {
        delegate?.centralManager(self, connectionEventDidOccur: event, for: SonarBTPeripheral.wrapperFor(peripheral, delegate: peripheralDelegate))
    }
    
    private func wrapState(_ dict: [String : Any]) -> [String : Any] {
        return dict.reduce([:]) { (partialResult: [String: Any], tuple: (key: String, value: Any)) in
            var result = partialResult
            switch (tuple.value) {
            case let peripherals as [CBPeripheral]: result[tuple.key] = peripherals.map { peripheral in                 SonarBTPeripheral.wrapperFor(peripheral, delegate: peripheralDelegate)
                }
            case let services as [CBMutableService]: result[tuple.key] = services.map { service in SonarBTService(service) }
            case let services as [CBService]: result[tuple.key] = services.map { service in SonarBTService(service) }
            case let characteristics as [CBCharacteristic]: result[tuple.key] = characteristics.map { characteristic in SonarBTCharacteristic(characteristic) }
            default:
                result[tuple.key] = tuple.value
            }
            return result
        }
    }
}


