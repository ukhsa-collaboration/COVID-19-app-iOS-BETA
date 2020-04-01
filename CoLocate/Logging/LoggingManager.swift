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
    
    private init() {
        if Self.isEnabled {
            // TODO: replace with our new log handlers.
            LoggingSystem.bootstrap(StreamLogHandler.standardOutput)
        } else {
            LoggingSystem.bootstrap { _ in NoOpLogHandler() }
        }
    }
    
    private static var isEnabled: Bool {
        // TODO: When should we log?
        return true
    }
    
}
