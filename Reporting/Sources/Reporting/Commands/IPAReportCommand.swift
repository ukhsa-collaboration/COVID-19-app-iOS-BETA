import Foundation
import ArgumentParser

struct IPAReportCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "ipa",
        abstract: "Produces report from an ipa file."
    )
    
    @Argument(help: "Path to the ipa to make a report for.")
    var ipa: String
    
    @Option(help: "Path to use for the output.")
    var output: String

    func run() throws {
        let fileManager = FileManager()
        
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        let reportFolder = URL(fileURLWithPath: output, relativeTo: currentDirectory)
        
        try fileManager.createDirectory(at: reportFolder, withIntermediateDirectories: true, attributes: nil)
        
        try withApplication { appURL in
            let reporter = ArtefactReporter(appURL: appURL, reportFolder: reportFolder)
            try reporter.run()
        }
    }
    
    private func withApplication(perform work: (URL) throws -> Void ) throws {
        let fileManager = FileManager()
        
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        let ipaURL = URL(fileURLWithPath: ipa, relativeTo: currentDirectory)
        
        let temp = try fileManager.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: ipaURL, create: true)
        defer { try? fileManager.removeItem(at: temp) }
        
        try Bash.run("unzip", ipa, "-d", "'\(temp.path)'")
        
        let applicationsFolder = temp
            .appendingPathComponent("Payload")
        
        guard let app = try fileManager.contentsOfDirectory(atPath: applicationsFolder.path).first(where: { $0.hasSuffix(".app") }) else {
            throw CustomError("Could not extract an app from \(ipa)")
        }
        
        try work(applicationsFolder.appendingPathComponent(app))
    }
    
}

