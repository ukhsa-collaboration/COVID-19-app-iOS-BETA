//
//  File.swift
//  
//
//  Created by NHSX.
//

import Foundation

struct ExecutableChecker {
    private let quotedPath: String
    init?(appURL: URL, appInfo: AppInfo) {
        guard let binaryName = appInfo.value(for: \.bundleExecutable) else {
            return nil
        }
        
        quotedPath = "'\(appURL.path)/\(binaryName)'"
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
}
