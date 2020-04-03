//
//  LogginManager.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Logging

class LoggingManager: NSObject {
    
    // `LoggingSystem` must be bootstrapped at most once.
    static let shared = LoggingManager()
    
    /// Call this as soon as possible in the app’s lifecycle so we do not miss any logs.
    static func bootstrap() {
        _ = shared
    }
    
    @objc dynamic private(set) var log = ""
    
    #if INTERNAL || DEBUG
    private let io = DispatchQueue(label: "Logging IO")
    private let stream = OutputStream.makeForLogs()
    
    private override init() {
        super.init()
        
        LoggingSystem.bootstrap { label in
            MultiplexLogHandler([
                StreamLogHandler.standardOutput(label: label),
                ForwardingLogHandler(label: label, send: self.log),
            ])
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
    #else
    private override init() {
        LoggingSystem.bootstrap { _ in NoOpLogHandler() }
    }
    #endif

}

#if INTERNAL || DEBUG

extension LogEvent {
    
    var description: String {
        if let metadata = self.metadata, !metadata.isEmpty {
            return "\(headline)\n\(metadata.description)"
        } else {
            return headline
        }
    }
    
    private var headline: String {
        "\(formatter.string(from: date)) \(level): \(label) – \(message)"
    }
    
}

private extension Logger.Metadata {
    
    var description: String {
        var string = ""
        appendDescription(into: &string)
        return string
    }
    
    func appendDescription(into description: inout String, depth: Int = 0) {
        let whitespace = repeatElement("  ", count: depth).joined()
        self.sorted { $0.key < $1.key }
            .forEach { (key, value) in
                description.append("\(whitespace)\(key): ")
                value.appendDescription(into: &description, depth: depth + 1)
        }
    }
    
}

private extension Logger.MetadataValue {
    
    func appendDescription(into description: inout String, depth: Int) {
        switch self {
        case .string(let string):
            description.append(string)
            description.append("\n")
        case .stringConvertible(let convertible):
            description.append(convertible.description)
            description.append("\n")
        case .dictionary(let dictionary):
            description.append("\n")
            dictionary.appendDescription(into: &description, depth: depth)
        case .array(let array):
            description.append("\n")
            array.forEach { value in
                let whitespace = repeatElement("  ", count: depth).joined()
                description.append("\(whitespace)- ")
                value.appendDescription(into: &description, depth: depth + 1)
            }
        }
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

#endif
