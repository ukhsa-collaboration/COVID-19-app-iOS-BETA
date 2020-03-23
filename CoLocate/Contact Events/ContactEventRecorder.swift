//
//  ContactEventRecorder.swift
//  CoLocate
//
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct ContactEvent: Equatable, Codable {
    let remoteContactId: UUID
    let timestamp: Date
    let rssi: Int
    
    init(remoteContactId: UUID, timestamp: Date = Date(), rssi: Int) {
        self.remoteContactId = remoteContactId
        self.timestamp = timestamp
        self.rssi = rssi
    }
}

protocol ContactEventRecorder {
    func record(_ contactEvent: ContactEvent)
    func reset()
    var contactEvents: [ContactEvent] { get }
}
