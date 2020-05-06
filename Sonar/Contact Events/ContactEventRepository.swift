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
    var items: [UUID: ContactEvent] { get }
    func update(item: ContactEvent, key: UUID)
    func replaceAll(with: [UUID: ContactEvent])
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
        let newItems = persister.items.filter { _, contactEvent in contactEvent.timestamp > date }
        persister.replaceAll(with: newItems)
    }
    
    func removeExpiredContactEvents(ttl: Double) {
        let expiryDate = Date(timeIntervalSinceNow: -ttl)
        remove(through: expiryDate)
    }
    
    func btleListener(_ listener: BTLEListener, didFind broadcastPayload: IncomingBroadcastPayload, for peripheral: BTLEPeripheral) {
        var event = persister.items[peripheral.identifier] ?? ContactEvent()
        event.broadcastPayload = broadcastPayload
        persister.update(item: event, key: peripheral.identifier)
        delegate?.repository(self, didRecord: broadcastPayload, for: peripheral)
    }
    
    func btleListener(_ listener: BTLEListener, didReadTxPower txPower: Int, for peripheral: BTLEPeripheral) {
        var contactEvent = persister.items[peripheral.identifier] ?? ContactEvent()
        contactEvent.txPower = Int8(txPower)
        persister.update(item: contactEvent, key: peripheral.identifier)
    }
    
    func btleListener(_ listener: BTLEListener, didReadRSSI RSSI: Int, for peripheral: BTLEPeripheral) {
        var event = persister.items[peripheral.identifier] ?? ContactEvent()
        event.recordRSSI(Int8(RSSI))
        persister.update(item: event, key: peripheral.identifier)
        delegate?.repository(self, didRecordRSSI: RSSI, for: peripheral)
    }

}

private let logger = Logger(label: "ContactEvents")
