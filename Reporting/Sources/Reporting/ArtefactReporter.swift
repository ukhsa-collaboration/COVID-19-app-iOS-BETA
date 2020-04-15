import Foundation
import ArgumentParser

struct ArtefactReporter: ParsableCommand {
    @Option(help: "Path to the archive to make a report for.")
    var archive: String
    
    @Option(help: "Path to use for the output.")
    var output: String

    func run() throws {
        let fileManager = FileManager()
        
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        let reportFolder = URL(fileURLWithPath: output, relativeTo: currentDirectory)
        
        try fileManager.createDirectory(at: reportFolder, withIntermediateDirectories: true, attributes: nil)
        
        let report = try self.report(for: findApplication())
        try report.save(to: reportFolder)
    }
    
    private func findApplication() throws -> URL {
        let fileManager = FileManager()
        
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        let archiveFolder = URL(fileURLWithPath: archive, relativeTo: currentDirectory)

        let applicationsFolder = archiveFolder
            .appendingPathComponent("Products")
            .appendingPathComponent("Applications")
        
        guard let app = try fileManager.contentsOfDirectory(atPath: applicationsFolder.path).first(where: { $0.hasSuffix(".app") }) else {
            throw CustomError("Could not find an app in archive \(archiveFolder)")
        }
        
        return applicationsFolder.appendingPathComponent(app)
    }
    
    private func report(for application: URL) throws -> Report {
        let page = ReportPage(name: "Summary", sections: [])
        return Report(pages: [page], attachments: [])
    }
}

