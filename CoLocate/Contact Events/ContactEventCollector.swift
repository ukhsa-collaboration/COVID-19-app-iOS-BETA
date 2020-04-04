//
//  ContactEventCollector.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

// TODO: Should maybe be a MutableContactEvent?
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
    
    func asContactEvent() -> ContactEvent? {
        if let sonarId  = self.sonarId {
            return ContactEvent(sonarId: sonarId, timestamp: timestamp, rssiValues: rssiSamples, duration: duration)
        } else {
            return nil
        }
    }

}

@objc class ContactEventCollector: NSObject, BTLEListenerDelegate {
    
    static let shared = ContactEventCollector()
    
    @objc dynamic var _connectedPeripheralCount: Int = 0
    
    var connectedPeripherals: [UUID: ConnectedPeripheral] = [:] {
        didSet {
            _connectedPeripheralCount = connectedPeripherals.count
        }
    }
    
    let contactEventRecorder: ContactEventRecorder
    
    // TODO: Should be private, but have to open it for tests. How do we do DI?
    init(contactEventRecorder: ContactEventRecorder = PlistContactEventRecorder.shared) {
        self.contactEventRecorder = contactEventRecorder
    }
    
    func btleListener(_ listener: BTLEListener, didConnect peripheral: BTLEPeripheral) {
        connectedPeripherals[peripheral.identifier] = ConnectedPeripheral(identifier: peripheral.identifier)
    }
    
    func btleListener(_ listener: BTLEListener, didDisconnect peripheral: BTLEPeripheral, error: Error?) {
        connectedPeripherals[peripheral.identifier]?.disconnect()
        if let connectedPeripheral = connectedPeripherals.removeValue(forKey: peripheral.identifier), let contactEvent = connectedPeripheral.asContactEvent() {
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

    func flush() {
        for (_, peripheral) in connectedPeripherals {
            if let contactEvent = peripheral.asContactEvent() {
                contactEventRecorder.record(contactEvent)
            }
        }
    }
}
