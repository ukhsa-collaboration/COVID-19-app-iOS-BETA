//
//  NoOpLogHandler.swift
//  Sonar
//
//  Created by NHSX on 01/04/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Logging

struct NoOpLogHandler: LogHandler {
    
    func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, file: String, function: String, line: UInt) {
        // Nothing
    }
    
    var metadata: Logger.Metadata = [:]
    
    var logLevel: Logger.Level = .critical
    
    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get {
            metadata[key]
        }
        set {
            metadata[key] = newValue
        }
    }
    
}
