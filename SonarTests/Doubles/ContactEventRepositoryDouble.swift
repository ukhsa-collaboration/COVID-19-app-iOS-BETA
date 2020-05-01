//
//  ContactEventRepositoryDouble.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
@testable import Sonar

class ContactEventRepositoryDouble: ContactEventRepository {
    var contactEvents: [ContactEvent]
    
    var delegate: ContactEventRepositoryDelegate?

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
    
    func btleListener(_ listener: BTLEListener, didFind broadcastPayload: IncomingBroadcastPayload, for peripheral: BTLEPeripheral) {
    }
    
    func btleListener(_ listener: BTLEListener, didReadRSSI RSSI: Int, for peripheral: BTLEPeripheral) {
    }
}
