//
//  ContactEventRepositoryDouble.swift
//  SonarTests
//
//  Created by NHSX on 4/13/20.
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
    
    func listener(_ listener: Listener, didFind broadcastPayload: IncomingBroadcastPayload, for peripheral: Peripheral) {
    }
    
    func listener(_ listener: Listener, didReadRSSI RSSI: Int, for peripheral: Peripheral) {
    }
    
    func listener(_ listener: Listener, didReadTxPower txPower: Int, for peripheral: Peripheral) {
    }
}
