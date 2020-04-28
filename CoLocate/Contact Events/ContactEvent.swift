//
//  ContactEvent.swift
//  Sonar
//
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct ContactEvent: Equatable, Codable {

    var encryptedRemoteContactId: Data? = nil
    private (set) var timestamp: Date = Date()
    private (set) var rssiValues: [Int] = []
    private (set) var rssiIntervals: [TimeInterval] = []
    private (set) var duration: TimeInterval = 0
    
    mutating func recordRSSI(_ rssi: Int, timestamp: Date = Date()) {
        rssiValues.append(rssi)
        rssiIntervals.append(timestamp.timeIntervalSince(self.timestamp.addingTimeInterval(duration)))
        duration = timestamp.timeIntervalSince(self.timestamp)
    }

    enum CodingKeys: String, CodingKey {
        case encryptedRemoteContactId
        case timestamp
        case rssiValues
        case rssiIntervals
        case duration
    }
}
