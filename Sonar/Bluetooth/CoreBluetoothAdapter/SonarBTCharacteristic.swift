//
//  SonarBTCharacteristic.swift
//  Sonar
//
//  Created by NHSX on 16/6/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CoreBluetooth

typealias SonarBTCharacteristicProperties = CBCharacteristicProperties
class SonarBTCharacteristic {
    private let cbCharacteristic: CBCharacteristic
    
    init(_ characteristic: CBCharacteristic) {
        self.cbCharacteristic = characteristic
    }
    
    init(type UUID: SonarBTUUID, properties: SonarBTCharacteristicProperties, value: Data?, permissions: SonarBTAttributePermissions) {
        self.cbCharacteristic = CBMutableCharacteristic(
            type: UUID,
            properties: properties,
            value: nil,
            permissions: permissions)
    }
    
    var uuid: SonarBTUUID {
        return cbCharacteristic.uuid
    }
    
    var value: Data? {
        return cbCharacteristic.value
    }
    
    var unwrap: CBCharacteristic {
        return cbCharacteristic
    }
    
    var unwrapMutable: CBMutableCharacteristic {
        return cbCharacteristic as! CBMutableCharacteristic
    }
}
