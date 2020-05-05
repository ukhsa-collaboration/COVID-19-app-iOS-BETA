//
//  ContactEventRepository.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Logging

protocol ContactEventRepositoryDelegate {
    
    func repository(_ repository: ContactEventRepository, didRecord broadcastPayload: IncomingBroadcastPayload, for peripheral: BTLEPeripheral)
    
    func repository(_ repository: ContactEventRepository, didRecordRSSI RSSI: Int, for peripheral: BTLEPeripheral)

}

protocol ContactEventRepository: BTLEListenerDelegate {
    var contactEvents: [ContactEvent] { get }
    var delegate: ContactEventRepositoryDelegate? { get set }
    func reset()
    func remove(through date: Date)
    func removeExpiredContactEvents(ttl: Double)
}

protocol ContactEventPersister {
    var items: [UUID: ContactEvent] { get set }
    func reset()
}

extension PlistPersister: ContactEventPersister where K == UUID, V == ContactEvent {
}

@objc class PersistingContactEventRepository: NSObject, ContactEventRepository {
    
    public var contactEvents: [ContactEvent] {
        return Array(persister.items.values)
    }

    public var delegate: ContactEventRepositoryDelegate?
    
    private var persister: ContactEventPersister
    
    internal init(persister: ContactEventPersister) {
        self.persister = persister
    }
    
    func reset() {
        persister.reset()
    }

    func remove(through date: Date) {
        // I doubt this is atomic, but the window should be extraordinarily small
        // so I'm not too worried about dropping contact events here.
        persister.items = persister.items.filter { _, contactEvent in contactEvent.timestamp > date }
    }
    
    func removeExpiredContactEvents(ttl: Double) {
        let expiryDate = Date(timeIntervalSinceNow: -ttl)
        remove(through: expiryDate)
    }
    
    func btleListener(_ listener: BTLEListener, didFind broadcastPayload: IncomingBroadcastPayload, for peripheral: BTLEPeripheral) {
        if persister.items[peripheral.identifier] == nil {
            persister.items[peripheral.identifier] = ContactEvent()
        }
        persister.items[peripheral.identifier]?.broadcastPayload = broadcastPayload
        delegate?.repository(self, didRecord: broadcastPayload, for: peripheral)
    }
    
    func btleListener(_ listener: BTLEListener, didReadTxPower txPower: Int, for peripheral: BTLEPeripheral) {
        var contactEvent = persister.items[peripheral.identifier] ?? ContactEvent()
        contactEvent.txPower = Int8(txPower)
        persister.items[peripheral.identifier] = contactEvent
    }
    
    func btleListener(_ listener: BTLEListener, didReadRSSI RSSI: Int, for peripheral: BTLEPeripheral) {
        if persister.items[peripheral.identifier] == nil {
            persister.items[peripheral.identifier] = ContactEvent()
        }
        persister.items[peripheral.identifier]?.recordRSSI(Int8(RSSI))
        delegate?.repository(self, didRecordRSSI: RSSI, for: peripheral)
    }

}

private let logger = Logger(label: "ContactEvents")
