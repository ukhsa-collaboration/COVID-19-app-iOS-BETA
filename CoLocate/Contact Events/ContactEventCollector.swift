//
//  ContactEventCollector.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Logging

struct MutableContactEvent {
    
    var sonarId: UUID?
    let timestamp: Date
    var rssiValues: [Int]
    var duration: TimeInterval

    init(timestamp: Date = Date()) {
        self.timestamp = timestamp
        self.rssiValues = []
        self.sonarId = nil
        self.duration = 0
    }
    
    mutating func disconnect() {
        duration = timestamp.timeIntervalSince(timestamp)
    }
    
    func asContactEvent() -> ContactEvent? {
        if let sonarId  = self.sonarId {
            return ContactEvent(sonarId: sonarId, timestamp: timestamp, rssiValues: rssiValues, duration: duration)
        } else {
            return nil
        }
    }

}

@objc class ContactEventCollector: NSObject, BTLEListenerDelegate {
    
    @objc dynamic var _connectedPeripheralCount: Int = 0
    
    var connectedPeripherals: [UUID: MutableContactEvent] = [:] {
        didSet {
            _connectedPeripheralCount = connectedPeripherals.count
        }
    }
    
    let contactEventRecorder: ContactEventRecorder
    
    init(contactEventRecorder: ContactEventRecorder) {
        self.contactEventRecorder = contactEventRecorder
    }
    
    func btleListener(_ listener: BTLEListener, didConnect peripheral: BTLEPeripheral) {
        connectedPeripherals[peripheral.identifier] = MutableContactEvent()
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
        connectedPeripherals[peripheral.identifier]?.rssiValues.append(RSSI)
    }

    func flush() {
        logger.info("flushing contact events for \(connectedPeripherals.count) peripherals")

        for (_, peripheral) in connectedPeripherals {
            if let contactEvent = peripheral.asContactEvent() {
                contactEventRecorder.record(contactEvent)
            }
        }
    }
}

private let logger = Logger(label: "ContactEvents")
