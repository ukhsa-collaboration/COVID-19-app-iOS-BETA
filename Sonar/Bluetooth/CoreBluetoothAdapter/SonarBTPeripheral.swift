//
//  SonarBTPeripheral.swift
//  Sonar
//
//  Created by NHSX on 16/6/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CoreBluetooth

class SonarBTDescriptor {
    private let cbDescriptor: CBDescriptor
    
    init(_ descriptor: CBDescriptor) {
        self.cbDescriptor = descriptor
    }
}

class SonarBTService {
    private let cbService: CBService
    
    init(_ service: CBService) {
        self.cbService = service
    }
}

class SonarBTCharacteristic {
    private let cbCharacteristic: CBCharacteristic
    
    init(_ characteristic: CBCharacteristic) {
        self.cbCharacteristic = characteristic
    }
}


protocol SonarBTPeripheralDelegate: class {
    func peripheral(_ peripheral: SonarBTPeripheral, didDiscoverServices error: Error?)
    func peripheral(_ peripheral: SonarBTPeripheral, didModifyServices invalidatedServices: [SonarBTService])
    func peripheral(_ peripheral: SonarBTPeripheral, didReadRSSI RSSI: NSNumber, error: Error?)
    func peripheral(_ peripheral: SonarBTPeripheral, didUpdateNotificationStateFor characteristic: SonarBTCharacteristic, error: Error?)
    func peripheral(_ peripheral: SonarBTPeripheral, didUpdateValueFor descriptor: SonarBTDescriptor, error: Error?)
    func peripheral(_ peripheral: SonarBTPeripheral, didDiscoverCharacteristicsFor service: SonarBTService, error: Error?)
    func peripheralDidUpdateName(_ peripheral: SonarBTPeripheral)
}

class SonarBTPeripheral: NSObject {
    private let cbPeripheral: CBPeripheral
    private weak var delegate: SonarBTPeripheralDelegate?
    
    init(_ peripheral: CBPeripheral, delegate: SonarBTPeripheralDelegate?) {
        self.cbPeripheral = peripheral
        self.delegate = delegate
        super.init()
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
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        delegate?.peripheral(self, didUpdateValueFor: SonarBTDescriptor(descriptor), error: error)
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
