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
    
    private let io = DispatchQueue(label: "Logging IO")
    private let stream: OutputStream
    
    // TODO: Use this to drive logging UI
    private(set) var log = ""
    
    private init() {
        if Self.isEnabled {
            stream = .makeForLogs()
            LoggingSystem.bootstrap { label in
                MultiplexLogHandler([
                    StreamLogHandler.standardOutput(label: label),
                    ForwardingLogHandler(label: label, send: self.log),
                ])
            }
        } else {
            stream = OutputStream(toMemory: ())
            LoggingSystem.bootstrap { _ in NoOpLogHandler() }
        }
        
        stream.open()
    }
    
    private func log(_ event: LogEvent) {
        let entry = "\(event.description)\n"
        DispatchQueue.main.async {
            self.log.append(entry)
        }
        io.async {
            let data = entry.data(using: .utf8)!
            data.withUnsafeBytes { buffer in
                let bytes = buffer.bindMemory(to: UInt8.self)
                self.stream.write(bytes.baseAddress!, maxLength: bytes.count)
            }
        }
    }
    
    private static var isEnabled: Bool {
        #warning("Address this before public release")
        // TODO: When should we log?
        return true
    }
    
}

extension LogEvent {
    
    var description: String {
        "\(formatter.string(from: date)) – \(label): \(message)"
    }
    
}

private let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_UK_POSIX")
    formatter.dateStyle = .none
    formatter.timeStyle = .medium
    return formatter
}()

private extension OutputStream {
    
    static func makeForLogs() -> OutputStream {
        let fileManager = FileManager()
        let fileName = ISO8601DateFormatter().string(from: Date())
        
        // Don’t really expect an error, but don’t want to crash because of this.
        guard let logsFolder = try? fileManager
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Logs") else {
                return OutputStream(toMemory: ())
        }
        
        try? fileManager.createDirectory(at: logsFolder, withIntermediateDirectories: true, attributes: nil)
        
        let file = logsFolder.appendingPathComponent("\(fileName).log")
        
        return OutputStream(url: file, append: false) ?? OutputStream(toMemory: ())
    }
    
}
