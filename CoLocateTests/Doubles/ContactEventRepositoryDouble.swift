//
//  ContactEventRepositoryDouble.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
@testable import CoLocate

class ContactEventRepositoryDouble: ContactEventRepository {
    var contactEvents: [ContactEvent] = []
    var hasReset = false
    
    func reset() {
        contactEvents = []
        hasReset = true
    }
    
    var removeExpiredEntriesCallbackCount = 0
    func removeExpiredContactEvents(ttl: Double) {
        removeExpiredEntriesCallbackCount += 1
    }

    func remove(through date: Date) {
    }
    
    func btleListener(_ listener: BTLEListener, didFind sonarId: Data, forPeripheral peripheral: BTLEPeripheral) {
    }
    
    func btleListener(_ listener: BTLEListener, didReadRSSI RSSI: Int, forPeripheral peripheral: BTLEPeripheral) {
    }
}
