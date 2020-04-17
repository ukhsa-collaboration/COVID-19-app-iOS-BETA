//
//  ContactEventRepository.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Logging

protocol ContactEventRepository {
    var contactEvents: [ContactEvent] { get }
    func reset()
    func removeExpiredContactEvents()
}

protocol ContactEventPersister {
    var items: [UUID: ContactEvent] { get set }
    func reset()
}

extension PlistPersister: ContactEventPersister where K == UUID, V == ContactEvent {
}

@objc class PersistingContactEventRepository: NSObject, BTLEListenerDelegate, ContactEventRepository {
    
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
    
    func removeExpiredContactEvents() {
        var copy = persister.items
        let expiryDate = Date(timeIntervalSinceNow: -2419200)
        
        persister.items.forEach({uuid, contactEvent in
            if contactEvent.timestamp < expiryDate {
                copy.removeValue(forKey: uuid)
            }
        })
        
        persister.items = copy
    }
    
    func btleListener(_ listener: BTLEListener, didFind sonarId: Data, forPeripheral peripheral: BTLEPeripheral) {
        if persister.items[peripheral.identifier] == nil {
            persister.items[peripheral.identifier] = ContactEvent()
        }
        persister.items[peripheral.identifier]?.sonarId = sonarId
    }
    
    func btleListener(_ listener: BTLEListener, didReadRSSI RSSI: Int, forPeripheral peripheral: BTLEPeripheral) {
        if persister.items[peripheral.identifier] == nil {
            persister.items[peripheral.identifier] = ContactEvent()
            listener.connect(peripheral)
        }
        persister.items[peripheral.identifier]?.recordRSSI(RSSI)
    }

}

private let logger = Logger(label: "ContactEvents")
