//
//  ContactEvent.swift
//  CoLocate
//
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct ContactEvent: Equatable, Decodable {

    var sonarId: Data? = nil
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
        case sonarId
        case timestamp
        case rssiValues
        case rssiIntervals
        case duration
    }
}

// Remove this once we're sending encrypted sonar ids is working
extension ContactEvent: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        if let uuid = sonarId.flatMap({ String(data: $0, encoding: .utf8) }).flatMap({ UUID(uuidString: $0) }) {
            try container.encode(uuid, forKey: .sonarId)
        } else {
            try container.encode(sonarId, forKey: .sonarId)
        }

        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(rssiValues, forKey: .rssiValues)
        try container.encode(rssiIntervals, forKey: .rssiIntervals)
        try container.encode(duration, forKey: .duration)
    }
}
