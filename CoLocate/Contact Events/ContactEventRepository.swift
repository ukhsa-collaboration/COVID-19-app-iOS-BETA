//
//  ContactEventRepository.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Logging

protocol ContactEventRepository: BTLEListenerDelegate {
    var contactEvents: [ContactEvent] { get }
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
    
    @objc dynamic public var _contactEventCount: Int {
        return persister.items.count
    }
    
    public var contactEvents: [ContactEvent] {
        return Array(persister.items.values)
    }
    
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
    
    func btleListener(_ listener: BTLEListener, didFind remoteEncryptedBroadcastId: Data, forPeripheral peripheral: BTLEPeripheral) {
        if persister.items[peripheral.identifier] == nil {
            persister.items[peripheral.identifier] = ContactEvent()
        }
        persister.items[peripheral.identifier]?.encryptedRemoteContactId = remoteEncryptedBroadcastId
    }
    
    func btleListener(_ listener: BTLEListener, didReadRSSI RSSI: Int, forPeripheral peripheral: BTLEPeripheral) {
        if persister.items[peripheral.identifier] == nil {
            persister.items[peripheral.identifier] = ContactEvent()
        }
        persister.items[peripheral.identifier]?.recordRSSI(RSSI)
    }

}

private let logger = Logger(label: "ContactEvents")
