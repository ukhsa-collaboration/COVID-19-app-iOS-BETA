//
//  SonarBTPeripheral.swift
//  Sonar
//
//  Created by NHSX on 16/6/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol SonarBTPeripheralDelegate: class {
    func peripheral(_ peripheral: SonarBTPeripheral, didDiscoverServices error: Error?)
    func peripheral(_ peripheral: SonarBTPeripheral, didModifyServices invalidatedServices: [SonarBTService])
    func peripheral(_ peripheral: SonarBTPeripheral, didReadRSSI RSSI: NSNumber, error: Error?)
    func peripheral(_ peripheral: SonarBTPeripheral, didUpdateNotificationStateFor characteristic: SonarBTCharacteristic, error: Error?)
    func peripheral(_ peripheral: SonarBTPeripheral, didUpdateValueFor characteristic: SonarBTCharacteristic, error: Error?)
    func peripheral(_ peripheral: SonarBTPeripheral, didDiscoverCharacteristicsFor service: SonarBTService, error: Error?)
    func peripheralDidUpdateName(_ peripheral: SonarBTPeripheral)
}

typealias SonarBTPeripheralState = CBPeripheralState
class SonarBTPeripheral: NSObject {
    private var cbPeripheral: CBPeripheral!
    public weak var delegate: SonarBTPeripheralDelegate?
    
    class func wrapperFor(_ peripheral: CBPeripheral, delegate: SonarBTPeripheralDelegate?) -> SonarBTPeripheral {
        return peripheral.delegate as? SonarBTPeripheral ?? SonarBTPeripheral(peripheral, delegate: delegate)
    }
    
    init(_ peripheral: CBPeripheral, delegate: SonarBTPeripheralDelegate?) {
        self.cbPeripheral = peripheral
        self.delegate = delegate
        super.init()
        cbPeripheral.delegate = self
    }
    
    init(delegate: SonarBTPeripheralDelegate?) {
        self.delegate = delegate
        super.init()
    }
    
    var services: [SonarBTService]? {
        return unwrap.services?.map { cbService in SonarBTService(cbService) }
    }
    
    var identifier: UUID {
        return cbPeripheral.identifier
    }
    
    var state: SonarBTPeripheralState {
        return cbPeripheral.state
    }

    var identifierWithName: String {
        return "\(cbPeripheral.identifier) (\(cbPeripheral.name ?? "unknown"))"
    }
    
    var unwrap: CBPeripheral {
        return cbPeripheral
    }
    
    func readRSSI() {
        cbPeripheral.readRSSI()
    }
    
    func discoverServices(_ serviceUUIDs: [SonarBTUUID]?) {
        cbPeripheral.discoverServices(serviceUUIDs)
    }
    
    func discoverCharacteristics(_ characteristicUUIDs: [SonarBTUUID]?, for service: SonarBTService) {
        cbPeripheral.discoverCharacteristics(characteristicUUIDs, for: service.unwrap)
    }
    
    func readValue(for characteristic: SonarBTCharacteristic) {
        cbPeripheral.readValue(for: characteristic.unwrap)
    }
    
    func setNotifyValue(_ enabled: Bool, for characteristic: SonarBTCharacteristic) {
        cbPeripheral.setNotifyValue(enabled, for: characteristic.unwrap)
    }
}

extension SonarBTPeripheral: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        delegate?.peripheral(self, didDiscoverServices: error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        delegate?.peripheral(self, didModifyServices: invalidatedServices.map{ cbService in SonarBTService(cbService) } )
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        delegate?.peripheral(self, didReadRSSI: RSSI, error: error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        delegate?.peripheral(self, didUpdateValueFor: SonarBTCharacteristic(characteristic), error: error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        delegate?.peripheral(self, didDiscoverCharacteristicsFor: SonarBTService(service), error: error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        delegate?.peripheral(self, didUpdateNotificationStateFor: SonarBTCharacteristic(characteristic), error: error)
    }
    
    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        delegate?.peripheralDidUpdateName(self)
    }
    
}
