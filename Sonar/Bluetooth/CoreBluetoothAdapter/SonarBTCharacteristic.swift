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
    
    var name: String {
        switch cbCharacteristic.uuid {
        case Environment.keepaliveCharacteristicUUID: return "Keepalive"
        case Environment.sonarIdCharacteristicUUID: return "SonarID"
        default: return "Unknown \(cbCharacteristic.uuid.uuidString)"
        }
    }
    
    var isSonarCharacteristic: Bool {
        return isSonarKeepalive || isSonarID
    }
    
    var isSonarKeepalive: Bool {
        return cbCharacteristic.uuid == Environment.keepaliveCharacteristicUUID
    }
    
    var isSonarID: Bool {
        return cbCharacteristic.uuid == Environment.sonarIdCharacteristicUUID
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
