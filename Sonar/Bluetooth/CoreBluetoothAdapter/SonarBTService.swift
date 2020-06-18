//
//  SonarBTService.swift
//  Sonar
//
//  Created by NHSX on 16/6/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CoreBluetooth

class SonarBTService {
    private let cbService: CBService!
    var characteristics: [SonarBTCharacteristic]? {
        get {
            return cbService.characteristics?.map { cbCharateristic in SonarBTCharacteristic(cbCharateristic) }
        }
        set {
            unwrapMutable.characteristics = newValue?.map { characteristic in characteristic.unwrapMutable }
        }
    }
    
    var sonarCharacteristics: [SonarBTCharacteristic]? {
        return characteristics?.filter { characteristic in characteristic.isSonarCharacteristic }
    }
    
    init(_ service: CBService) {
        self.cbService = service
    }
    
    init(type UUID: SonarBTUUID, primary isPrimary: Bool) {
        self.cbService = CBMutableService(type: UUID, primary: isPrimary)
    }
    
    var uuid: SonarBTUUID {
        return cbService.uuid
    }
    
    var name: String {
        switch cbService.uuid {
        case Environment.sonarServiceUUID: return "Sonar Service"
        default: return "Unknown Service"
        }
    }
    
    var unwrap: CBService {
        return cbService
    }
    
    var unwrapMutable: CBMutableService {
        return cbService as! CBMutableService
    }
}
