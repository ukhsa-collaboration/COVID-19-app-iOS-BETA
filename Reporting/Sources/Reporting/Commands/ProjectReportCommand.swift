import Foundation
import ArgumentParser

struct ProjectReportCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "project",
        abstract: "Produces report from an Xcode project."
    )
    
    enum Method: String, ExpressibleByArgument {
        case archive
        case build
    }
    
    @Argument(help: "Path to the project to make a report for.")
    var project: String
    
    @Option(help: "Name of scheme to archive.")
    var scheme: String

    @Option(help: "How the application should be created")
    var method: Method

    @Option(help: "Path to use for the output.")
    var output: String

    func run() throws {
        switch method {
        case .archive:
            try withArchive { archiveURL in
                var command = ArchiveReportCommand()
                command.archive = archiveURL.path
                command.output = output
                
                try command.run()
            }
        case .build:
            try withApplication { appURL in
                let fileManager = FileManager()
                
                let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
                let reportFolder = URL(fileURLWithPath: output, relativeTo: currentDirectory)
                
                try fileManager.createDirectory(at: reportFolder, withIntermediateDirectories: true, attributes: nil)
                
                let reporter = ArtefactReporter(appURL: appURL, reportFolder: reportFolder)
                try reporter.run()
            }
        }
    }
    
    private func withArchive(perform work: (URL) throws -> Void) throws {
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
    
    private func withApplication(perform work: (URL) throws -> Void) throws {
        let fileManager = FileManager()
        
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        
        let temp = try fileManager.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: currentDirectory, create: true)
        defer { try? fileManager.removeItem(at: temp) }
        
        let derivedDataURL = temp
        
        try Bash.run(
            "xcodebuild",
            "build",
            "-project", project,
            "-scheme", scheme,
            "-configuration", "release",
            "-sdk", "iphoneos13.4",
            "-derivedDataPath", "\"\(derivedDataURL.path)\"",
            "CODE_SIGNING_ALLOWED=NO"
        )
        
        let applicationsFolder = derivedDataURL
            .appendingPathComponent("Build")
            .appendingPathComponent("Products")
            .appendingPathComponent("Release-iphoneos")
        
        guard let app = try fileManager.contentsOfDirectory(atPath: applicationsFolder.path).first(where: { $0.hasSuffix(".app") }) else {
            throw CustomError("Could not find an app in derived data \(derivedDataURL)")
        }
        
        try work(applicationsFolder.appendingPathComponent(app))
    }
    
}
