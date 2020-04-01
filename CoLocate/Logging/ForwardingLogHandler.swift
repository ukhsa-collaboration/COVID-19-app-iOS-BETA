//
//  InMemoryLogHandler.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Logging

struct ForwardingLogHandler: LogHandler {
    
    let label: String
    
    private let send: (LogEvent) -> Void
    
    var metadata = Logger.Metadata()
    
    var logLevel = Logger.Level.debug
    
    init(label: String, send: @escaping (LogEvent) -> Void) {
        self.label = label
        self.send = send
    }
    
    func log(level: Logger.Level,
             message: Logger.Message,
             metadata: Logger.Metadata?,
             file: String, function: String, line: UInt) {
        send(
            LogEvent(
                label: label,
                level: level,
                message: message,
                metadata: metadata,
                date: Date(),
                file: file,
                function: function,
                line: line
            )
        )
    }
    
    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get {
            metadata[key]
        }
        set {
            metadata[key] = newValue
        }
    }
    
}
