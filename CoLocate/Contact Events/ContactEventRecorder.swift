//
//  ContactEventRecorder.swift
//  CoLocate
//
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct OldContactEvent: Equatable, Codable {
    let remoteContactId: UUID
    let timestamp: Date
    let rssi: Int
    
    init(remoteContactId: UUID, timestamp: Date = Date(), rssi: Int) {
        self.remoteContactId = remoteContactId
        self.timestamp = timestamp
        self.rssi = rssi
    }
}

struct ContactEvent: Equatable, Codable {
    let sonarId: UUID
    let timestamp: Date
    let rssiValues: [Int]
    let duration: TimeInterval
}


protocol ContactEventRecorder {
    func record(_ contactEvent: OldContactEvent)
    func record(_ contactEvent: ContactEvent)
    func reset()
    var oldContactEvents: [OldContactEvent] { get }
    var contactEvents: [ContactEvent] { get }
}
