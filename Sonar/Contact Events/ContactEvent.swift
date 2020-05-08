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
    private (set) var rssiTimestamps: [Date]
    private (set) var duration: TimeInterval

    // Deprecated, but has to be here for Codable conformance
    private let rssiIntervals: [TimeInterval]?
    
    init(
        broadcastPayload: IncomingBroadcastPayload? = nil,
        txPower: Int8 = 0,
        timestamp: Date = Date(),
        rssiValues: [Int8] = [],
        rssiTimestamps: [Date] = [],
        duration: TimeInterval = 0
    ) {
        self.broadcastPayload = broadcastPayload
        self.txPower = txPower
        self.timestamp = timestamp
        self.rssiValues = rssiValues
        self.rssiTimestamps = rssiTimestamps
        self.rssiIntervals = nil
        self.duration = duration
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        broadcastPayload = try values.decodeIfPresent(IncomingBroadcastPayload.self, forKey: .broadcastPayload)
        timestamp = try values.decode(Date.self, forKey: .timestamp)
        rssiValues = try values.decode([Int8].self, forKey: .rssiValues)
        duration = try values.decode(TimeInterval.self, forKey: .duration)

        // v1.0.1, build 341 and earlier doesn't serialize txPower
        txPower = (try? values.decode(Int8.self, forKey: .txPower)) ?? 0

        // v1.0.2 build 356 serialised rssiIntervals (offsets from timestamp for the 0th, then the previous rssi)
        // Now we just store timestamps as they needed to be 32 bit anyway
        self.rssiIntervals = nil
        self.rssiTimestamps = []
        if let rssiIntervals = try? values.decode([TimeInterval].self, forKey: .rssiIntervals) {
            let result: (cumulativeInterval: Double, timestamps: [Date]) = rssiIntervals.reduce(into: (0.0, [])) { ( result: inout (cumulativeInterval: Double, timestamps: [Date]), interval: TimeInterval) in
                result.cumulativeInterval += interval
                result.timestamps.append(self.timestamp + result.cumulativeInterval)
            }
            self.rssiTimestamps = result.timestamps
        } else {
            self.rssiTimestamps = try values.decode([Date].self, forKey: .rssiTimestamps)
        }
    }

    mutating func recordRSSI(_ rssi: Int8, timestamp: Date = Date()) {
        rssiValues.append(rssi)
        rssiTimestamps.append(timestamp)
        duration = timestamp.timeIntervalSince(self.timestamp)
    }

    mutating func merge(_ contactEvent: ContactEvent) {
        let merged = zip(
            rssiTimestamps + contactEvent.rssiTimestamps,
            rssiValues + contactEvent.rssiValues
        ).sorted(by: { $0.0 < $1.0 } )
        rssiTimestamps = merged.map({ $0.0 })
        rssiValues = merged.map({ $0.1 })
        txPower = contactEvent.txPower
    }
    
    private enum CodingKeys: String, CodingKey {
        case broadcastPayload
        case timestamp
        case rssiValues
        case rssiIntervals // deprecated, but must remain for codable conformance
        case rssiTimestamps
        case duration
        case txPower
    }

}
