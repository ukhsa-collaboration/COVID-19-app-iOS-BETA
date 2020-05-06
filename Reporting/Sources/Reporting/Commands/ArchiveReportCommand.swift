import Foundation
import ArgumentParser

struct ArchiveReportCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "archive",
        abstract: "Produces report from an Xcode archive."
    )
    
    @Argument(help: "Path to the archive to make a report for.")
    var archive: String
    
    @Option(help: "Path to use for the output.")
    var output: String

    func run() throws {
        let fileManager = FileManager()
        
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        let reportFolder = URL(fileURLWithPath: output, relativeTo: currentDirectory)
        
        try fileManager.createDirectory(at: reportFolder, withIntermediateDirectories: true, attributes: nil)
        
        let appURL = try findApplication()
        let reporter = ArtefactReporter(appURL: appURL, reportFolder: reportFolder)
        try reporter.run()
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
    
}

