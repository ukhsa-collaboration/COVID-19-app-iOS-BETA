import Foundation
import ArgumentParser

struct Integrity: ParsableCommand {
    @Option(help: "Path to the archive to make a report for.")
    var archive: String
    
    @Option(help: "Path to the prepared report.")
    var report: String

    func run() throws {
        let fileManager = FileManager()
        
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        let reportFolder = URL(fileURLWithPath: report, relativeTo: currentDirectory)
        
        try fileManager.createDirectory(at: reportFolder, withIntermediateDirectories: true, attributes: nil)
        
        try findApplication().path.write(to: reportFolder.appendingPathComponent("Report2.md"), atomically: true, encoding: .utf8)
    }
    
    private func findApplication() throws -> URL {
        let fileManager = FileManager()
        
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        let archiveFolder = URL(fileURLWithPath: archive, relativeTo: currentDirectory)

        let applicationsFolder = archiveFolder
            .appendingPathComponent("Products")
            .appendingPathComponent("Applications")
        
        guard let app = try fileManager.contentsOfDirectory(atPath: applicationsFolder.path).first(where: { $0.hasSuffix(".app") }) else {
            throw ReportError("Could not find an app in archive \(archiveFolder)")
        }
        
        return applicationsFolder.appendingPathComponent(app)
    }
}

