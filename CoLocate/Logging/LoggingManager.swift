//
//  LogginManager.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Logging

class LoggingManager {
    
    // `LoggingSystem` must be bootstrapped at most once.
    static let shared = LoggingManager()
    
    /// Call this as soon as possible in the app’s lifecycle so we do not miss any logs.
    static func bootstrap() {
        _ = shared
    }
    
    // TODO: Use this to drive logging UI
    private(set) var events = [LogEvent]()
    
    private init() {
        if Self.isEnabled {
            LoggingSystem.bootstrap { label in
                MultiplexLogHandler([
                    // For console:
                    StreamLogHandler.standardOutput(label: label),
                    
                    // For UI:
                    ForwardingLogHandler(label: label) { event in
                        DispatchQueue.main.async {
                            self.events.append(event)
                        }
                    }
                ])
            }
        } else {
            LoggingSystem.bootstrap { _ in NoOpLogHandler() }
        }
    }
    
    private static var isEnabled: Bool {
        // TODO: When should we log?
        return true
    }
    
}
