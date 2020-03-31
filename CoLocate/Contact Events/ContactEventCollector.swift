//
//  ContactEventCollector.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct ConnectedPeripheral {
    
    let identifier: UUID
    let timestamp: Date
    var rssiSamples: [Int]
    var sonarId: UUID?
    var duration: TimeInterval

    init(identifier: UUID, timestamp: Date = Date()) {
        self.identifier = identifier
        self.timestamp = timestamp
        self.rssiSamples = []
        self.sonarId = nil
        self.duration = 0
    }
    
    mutating func disconnect() {
        duration = timestamp.timeIntervalSince(timestamp)
    }

}

class ContactEventCollector: BTLEListenerDelegate {
    
    var connectedPeripherals: [UUID: ConnectedPeripheral] = [:]
    
    let contactEventRecorder: ContactEventRecorder
    
    init(contactEventRecorder: ContactEventRecorder) {
        self.contactEventRecorder = contactEventRecorder
    }
    
    func btleListener(_ listener: BTLEListener, didConnect peripheral: BTLEPeripheral) {
        connectedPeripherals[peripheral.identifier] = ConnectedPeripheral(identifier: peripheral.identifier)
    }
    
    func btleListener(_ listener: BTLEListener, didDisconnectPeripheral peripheral: BTLEPeripheral, error: Error?) {
        connectedPeripherals[peripheral.identifier]?.disconnect()
        if let connectedPeripheral = connectedPeripherals.removeValue(forKey: peripheral.identifier), let sonarId = connectedPeripheral.sonarId {
            let contactEvent = ContactEvent(remoteContactId: sonarId, timestamp: connectedPeripheral.timestamp, rssi: 0)
            contactEventRecorder.record(contactEvent)
        }
    }

    func btleListener(_ listener: BTLEListener, didFindSonarId sonarId: UUID, forPeripheral peripheral: BTLEPeripheral) {
        connectedPeripherals[peripheral.identifier]?.sonarId = sonarId
    }
    
    func btleListener(_ listener: BTLEListener, shouldReadRSSIFor peripheral: BTLEPeripheral) -> Bool {
        return connectedPeripherals[peripheral.identifier] != nil
    }
    
    func btleListener(_ listener: BTLEListener, didReadRSSI RSSI: Int, forPeripheral peripheral: BTLEPeripheral) {
        connectedPeripherals[peripheral.identifier]?.rssiSamples.append(RSSI)
    }
    
}
