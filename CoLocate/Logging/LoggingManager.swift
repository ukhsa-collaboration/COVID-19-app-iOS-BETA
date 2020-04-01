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
        // TODO: replace with our new log handlers.
        LoggingSystem.bootstrap(StreamLogHandler.standardOutput)
    }
    
}
