//
//  CBManagerState+CustomStringConvertible.swift
//  Sonar
//
//  Created by NHSX on 03.04.20.
//  Copyright © 2020 NHSX. All rights reserved.
//

extension SonarBTManagerState: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .poweredOff: return ".poweredOff"
        case .poweredOn: return ".poweredOn"
        case .resetting: return ".resetting"
        case .unauthorized: return ".unauthorized"
        case .unknown: return ".unknown"
        case .unsupported: return ".unsupported"
        @unknown default: return "unknown value"
        }
    }
    
}

extension SonarBTPeripheralState: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .connected: return ".connected"
        case .connecting: return ".connecting"
        case .disconnected: return ".disconnected"
        case .disconnecting: return ".disconnecting"
        @unknown default: return "unknown value"
        }
    }

}

extension Sequence where Iterator.Element == SonarBTService {
    
    func sonarIdService() -> SonarBTService? {
        return first(where: {$0.uuid == Environment.sonarServiceUUID})
    }
    
}

extension Sequence where Iterator.Element == SonarBTCharacteristic {
    
    func sonarIdCharacteristic() -> SonarBTCharacteristic? {
        return first(where: {$0.uuid == Environment.sonarIdCharacteristicUUID})
    }

}

extension Sequence where Iterator.Element == SonarBTCharacteristic {
    
    func keepaliveCharacteristic() -> SonarBTCharacteristic? {
        return first(where: {$0.uuid == Environment.keepaliveCharacteristicUUID})
    }

}
