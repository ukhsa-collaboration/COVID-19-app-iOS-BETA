//
//  CBManagerState+CustomStringConvertible.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import CoreBluetooth

extension CBManagerState: CustomStringConvertible {
    
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

extension CBPeripheralState: CustomStringConvertible {
    
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

extension CBPeripheral {
    
    public var identifierWithName: String {
        return "\(identifier) (\(name ?? "unknown"))"
    }
    
}

extension Sequence where Iterator.Element == CBService {
    
    func sonarIdService() -> CBService? {
        return first(where: {$0.uuid == ConcreteBTLEBroadcaster.sonarServiceUUID})
    }
    
}

extension Sequence where Iterator.Element == CBCharacteristic {
    
    func sonarIdCharacteristic() -> CBCharacteristic? {
        return first(where: {$0.uuid == ConcreteBTLEBroadcaster.sonarIdCharacteristicUUID})
    }

}

extension Sequence where Iterator.Element == CBCharacteristic {
    
    func keepaliveCharacteristic() -> CBCharacteristic? {
        return first(where: {$0.uuid == ConcreteBTLEBroadcaster.keepaliveCharacteristicUUID})
    }

}