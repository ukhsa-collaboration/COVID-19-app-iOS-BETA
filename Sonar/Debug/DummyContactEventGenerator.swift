//
//  DummyContactEventGenerator.swift
//  Sonar
//
//  Created by NHSX on 21.05.20
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Logging

class DummyContactEventGenerator {
    
    lazy var durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .default
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    let listener: Listener = StubListener()
    
    let delegate: ListenerDelegate
    
    init(delegate: ListenerDelegate) {
        self.delegate = delegate
    }
    
    func generate(eventCount: Int, rssiCount: Int) {
        let peripheral = StubPeripheral()
        let start = Date()
        do {
            for _ in 0..<eventCount {
                let eventStart = Date()
                delegate.listener(listener, didFind: try broadcastPayload(), for: peripheral)
                delegate.listener(listener, didReadTxPower: Int(Int8.random(in: Int8.min...Int8.max)), for: peripheral)
                for _ in 0..<rssiCount {
                    autoreleasepool {
                        delegate.listener(listener, didReadRSSI: Int(Int8.random(in: Int8.min...Int8.max)), for: peripheral)
                    }
                }
                let duration = durationFormatter.string(from: Date().timeIntervalSince(eventStart))!
                logger.info("Generated one event with \(rssiCount) RSSI readings in \(duration)")
            }
        } catch let error {
            logger.error("Failed to generate contact events: \(error)")
        }
        let duration = durationFormatter.string(from: Date().timeIntervalSince(start))!
        logger.info("Generated \(eventCount) events with \(rssiCount) RSSI readings in \(duration)")
    }
    
    private func broadcastPayload() throws -> IncomingBroadcastPayload {
        var data = Data(count: BroadcastPayload.length)
        let result = data.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, $0.count, $0.baseAddress!)
        }
        guard result == errSecSuccess else {
            throw NSError(domain: "DebugErrorDomain", code: 1)
        }
        return IncomingBroadcastPayload(data: data)
    }
    
    let logger = Logger(label: "Debug")
    
}

struct StubListener: Listener {
    func start(stateDelegate: ListenerStateDelegate?, delegate: ListenerDelegate?) {
    }
    func isHealthy() -> Bool {
        return true
    }
}

struct StubPeripheral: Peripheral {
    let identifier = UUID()
}
