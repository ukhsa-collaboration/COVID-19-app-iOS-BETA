//
//  ContactEvent.swift
//  Sonar
//
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct ContactEvent: Equatable, Codable {

    var encryptedRemoteContactId: Data? {
        return broadcastPayload?.cryptogram
    }
    
    var broadcastPayload: IncomingBroadcastPayload?

    var txPower: Int8
    private (set) var timestamp: Date
    private (set) var rssiValues: [Int8]
    private (set) var rssiIntervals: [TimeInterval]
    private (set) var duration: TimeInterval
    
    init(
        broadcastPayload: IncomingBroadcastPayload? = nil,
        txPower: Int8 = 0,
        timestamp: Date = Date(),
        rssiValues: [Int8] = [],
        rssiIntervals: [TimeInterval] = [],
        duration: TimeInterval = 0
    ) {
        self.broadcastPayload = broadcastPayload
        self.txPower = txPower
        self.timestamp = timestamp
        self.rssiValues = rssiValues
        self.rssiIntervals = rssiIntervals
        self.duration = duration
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        broadcastPayload = try values.decodeIfPresent(IncomingBroadcastPayload.self, forKey: .broadcastPayload)
        timestamp = try values.decode(Date.self, forKey: .timestamp)
        rssiValues = try values.decode([Int8].self, forKey: .rssiValues)
        rssiIntervals = try values.decode([TimeInterval].self, forKey: .rssiIntervals)
        duration = try values.decode(TimeInterval.self, forKey: .duration)
        // v1.0.1, build 341 and earlier don't serialize txPower
        txPower = (try? values.decode(Int8.self, forKey: .txPower)) ?? 0
    }

    mutating func recordRSSI(_ rssi: Int8, timestamp: Date = Date()) {
        rssiValues.append(rssi)
        rssiIntervals.append(timestamp.timeIntervalSince(self.timestamp.addingTimeInterval(duration)))
        duration = timestamp.timeIntervalSince(self.timestamp)
    }

    private enum CodingKeys: String, CodingKey {
        case broadcastPayload
        case timestamp
        case rssiValues
        case rssiIntervals
        case duration
        case txPower
    }

}
