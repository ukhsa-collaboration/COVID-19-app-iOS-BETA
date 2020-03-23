//
//  ContactEventRecorder.swift
//  CoLocate
//
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct ContactEvent: Equatable, Codable {
    let uuid: UUID
    let timestamp: Date
    let rssi: Int
    
    init(uuid: UUID, timestamp: Date = Date(), rssi: Int) {
        self.uuid = uuid
        self.timestamp = timestamp
        self.rssi = rssi
    }
}

protocol ContactEventRecorder {
    func record(_ contactEvent: ContactEvent)
    func reset()
    var contactEvents: [ContactEvent] { get }
}
