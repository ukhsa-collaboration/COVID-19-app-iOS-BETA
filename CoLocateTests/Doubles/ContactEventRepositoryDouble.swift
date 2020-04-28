//
//  ContactEventRepositoryDouble.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
@testable import CoLocate

class ContactEventRepositoryDouble: ContactEventRepository {
    var contactEvents: [ContactEvent]

    init(contactEvents: [ContactEvent] = []) {
        self.contactEvents = contactEvents
    }

    var hasReset = false
    
    func reset() {
        contactEvents = []
        hasReset = true
    }
    
    var removeExpiredEntriesCallbackCount = 0
    func removeExpiredContactEvents(ttl: Double) {
        removeExpiredEntriesCallbackCount += 1
    }

    var removedThroughDate: Date?
    func remove(through date: Date) {
        removedThroughDate = date
    }
    
    func btleListener(_ listener: BTLEListener, didFind sonarId: Data, forPeripheral peripheral: BTLEPeripheral) {
    }
    
    func btleListener(_ listener: BTLEListener, didReadRSSI RSSI: Int, forPeripheral peripheral: BTLEPeripheral) {
    }
}
