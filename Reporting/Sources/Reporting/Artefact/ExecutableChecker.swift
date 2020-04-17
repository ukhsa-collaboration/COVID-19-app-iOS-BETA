//
//  File.swift
//  
//
//  Created by NHSX.
//

import Foundation

struct ExecutableChecker {
    private let appURL: URL
    private let binaryName: String
    
    init?(appURL: URL, appInfo: AppInfo) {
        guard let binaryName = appInfo.value(for: \.bundleExecutable) else {
            return nil
        }
        
        self.appURL = appURL
        self.binaryName = binaryName
    }
    
    private var quotedPath: String {
        "'\(path)'"
    }
    
    private var path: String {
        "\(appURL.path)/\(binaryName)"
    }
    
    var linkedLibraries: [String] {
        guard
            let result = try? Bash.runAndCapture("otool", "-L", quotedPath),
            let string = String(data: result, encoding: .utf8) else {
            return []
        }
        
        let linkDeclarations = string.components(separatedBy: "\n")
            .lazy
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .dropFirst()
        
        let pathSpecifiers = linkDeclarations.map { $0.components(separatedBy: " ")[0] }
        
        let pathSpecifiersExcludingSwift = pathSpecifiers.filter {
            !$0.hasPrefix("@rpath/libswift")
        }

        let libraryNames = pathSpecifiersExcludingSwift.map { $0.components(separatedBy: "/").last! }

        return Array(libraryNames.sorted())
    }
    
    func checkHasNoAbsolutePaths() -> IntegrityCheck.Result {
        let pattern = "/.*/.*"
        let count = strings.count { $0.matches(pattern) }
        switch count {
        case 0:
            return .passed
            
        default:
            return .failed(message: "Found \(count) matches for `\(pattern)`")
        }
    }
    
    private var strings: [String] {
        // I think `string` waits for its std out to actually read stuff, causing it not to work with current
        // implementation of `runAndCapture`.
        let textsPath = "\(path).txt"
        try? Bash.run("strings", "-a", quotedPath, ">", "'\(textsPath)'")
        guard let string = try? String(contentsOfFile: textsPath) else {
            return []
        }
        
        return string.components(separatedBy: "\n")
    }
}
