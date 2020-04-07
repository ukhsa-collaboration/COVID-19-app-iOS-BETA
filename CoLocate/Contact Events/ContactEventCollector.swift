//
//  ContactEventCollector.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Logging

@objc class ContactEventCollector: NSObject, BTLEListenerDelegate {
    
    @objc dynamic var _contactEventCount: Int = 0
    
    var contactEvents: [UUID: ContactEvent] = [:] {
        didSet {
            _contactEventCount = contactEvents.count
        }
    }
    
    let contactEventRecorder: ContactEventRecorder
    
    init(contactEventRecorder: ContactEventRecorder) {
        self.contactEventRecorder = contactEventRecorder
    }
    
    func btleListener(_ listener: BTLEListener, didFindSonarId sonarId: UUID, forPeripheral peripheral: BTLEPeripheral) {
        contactEvents[peripheral.identifier] = ContactEvent(sonarId: sonarId)
    }
    
    func btleListener(_ listener: BTLEListener, didDisconnect peripheral: BTLEPeripheral, error: Error?) {
        contactEvents[peripheral.identifier]?.disconnect()
        if let connectedPeripheral = contactEvents.removeValue(forKey: peripheral.identifier) {
            contactEventRecorder.record(connectedPeripheral)
        }
    }

    func btleListener(_ listener: BTLEListener, shouldReadRSSIFor peripheral: BTLEPeripheral) -> Bool {
        return contactEvents[peripheral.identifier] != nil
    }
    
    func btleListener(_ listener: BTLEListener, didReadRSSI RSSI: Int, forPeripheral peripheral: BTLEPeripheral) {
        contactEvents[peripheral.identifier]?.rssiValues.append(RSSI)
    }

    func flush() {
        logger.info("flushing \(contactEvents.count) contact events")

        for (_, event) in contactEvents {
            contactEventRecorder.record(event)
        }
    }

}

private let logger = Logger(label: "ContactEvents")
