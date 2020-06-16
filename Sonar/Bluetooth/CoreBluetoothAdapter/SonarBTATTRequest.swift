//
//  SonarBTATTRequest.swift
//  Sonar
//
//  Created by NHSX on 16/6/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CoreBluetooth

typealias SonarBTATTError = CBATTError
class SonarBTATTRequest {
    private let cbATTRequest: CBATTRequest
    
    init(_ request: CBATTRequest) {
        self.cbATTRequest = request
    }
    
    var characteristic: SonarBTCharacteristic {
        return SonarBTCharacteristic(cbATTRequest.characteristic)
    }
    
    var unwrap: CBATTRequest {
        return cbATTRequest
    }
    
    var value: Data? {
        get {
            return cbATTRequest.value
        }
        
        set {
            cbATTRequest.value = newValue
        }
    }
}
