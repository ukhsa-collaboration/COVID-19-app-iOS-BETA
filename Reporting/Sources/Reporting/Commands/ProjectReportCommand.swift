import Foundation
import ArgumentParser

struct ProjectReportCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "project",
        abstract: "Produces report from an Xcode project."
    )
    
    @Argument(help: "Path to the project to make a report for.")
    var project: String
    
    @Option(help: "Name of scheme to archive.")
    var scheme: String

    @Option(help: "Path to use for the output.")
    var output: String

    func run() throws {
        try withArchive { archiveURL in
            var command = ArchiveReportCommand()
            command.archive = archiveURL.path
            command.output = output
            
            try command.run()
        }
    }
    
    private func withArchive(perform work: (URL) throws -> Void ) throws {
        let fileManager = FileManager()
        
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        
        let temp = try fileManager.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: currentDirectory, create: true)
        defer { try? fileManager.removeItem(at: temp) }
        
        let archiveURL = temp
            .appendingPathComponent("archive")
            .appendingPathExtension("xcarchive")

        try Bash.run(
            "xcodebuild",
            "archive",
            "-project", project,
            "-scheme", scheme,
            "-archivePath", "\"\(archiveURL.path)\""
        )
        
        try work(archiveURL)
    }
    
}

