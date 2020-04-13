//
//  ContactEventCollector.swift
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
}

protocol ContactEventPersister {
    var items: [ContactEvent] { get set }
    func reset()
}

extension PlistPersister: ContactEventPersister where T == ContactEvent {
}

@objc class PersistingContactEventRepository: NSObject, BTLEListenerDelegate, ContactEventRepository {
    
    public static let shared = PersistingContactEventRepository(persister: PlistPersister<ContactEvent>(fileName: "contactEvents"))
    
    @objc dynamic public var _contactEventCount: Int {
        return persister.items.count
    }
    
    public var contactEvents: [ContactEvent] {
        return persister.items
    }
    
    internal var peripheralIdentifierToContactEvent: [UUID: ContactEvent] = [:] {
        didSet {
            persister.items = Array(peripheralIdentifierToContactEvent.values)
        }
    }
    
    private var persister: ContactEventPersister
    
    internal init(persister: ContactEventPersister) {
        self.persister = persister
    }
    
    func reset() {
        persister.reset()
    }
    
    func btleListener(_ listener: BTLEListener, didFind sonarId: Data, forPeripheral peripheral: BTLEPeripheral) {
        if peripheralIdentifierToContactEvent[peripheral.identifier] == nil {
            peripheralIdentifierToContactEvent[peripheral.identifier] = ContactEvent()
        }
        peripheralIdentifierToContactEvent[peripheral.identifier]?.sonarId = sonarId
    }
    
    func btleListener(_ listener: BTLEListener, didReadRSSI RSSI: Int, forPeripheral peripheral: BTLEPeripheral) {
        if peripheralIdentifierToContactEvent[peripheral.identifier] == nil {
            peripheralIdentifierToContactEvent[peripheral.identifier] = ContactEvent()
            listener.connect(peripheral)
        }
        peripheralIdentifierToContactEvent[peripheral.identifier]?.recordRSSI(RSSI)
    }

}

private let logger = Logger(label: "ContactEvents")
