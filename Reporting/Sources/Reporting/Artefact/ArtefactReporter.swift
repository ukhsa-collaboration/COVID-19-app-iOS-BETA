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
    
    private func report(for appURL: URL) throws -> Report {
        
        let infoURL = appURL.appendingPathComponent("Info.plist")
        
        let data = try Data(contentsOf: infoURL)
        let appInfo = try PropertyListDecoder().decode(AppInfo.self, from: data)
        
        let appInfoReporter = AppInfoReporter(compilationRequirements: CoLocate.compilationRequirements)
        let appFilesReporter = AppFilesReporter()
        
        return Report(
            pages: [
                ReportPage(
                    name: "Overview",
                    sections: [
                        [
                            ReportSection(
                                title: "App Icon",
                                content: "![App icon](Attachments/Icon.png)"),
                        ],
                        appInfoReporter.overviewSections(for: appInfo),
                        [
                            ReportSection(
                                title: "Integrity Checks",
                                content: "See [Integrity Checks](IntegrityChecks.md) for more technical reports."),
                        ],
                        ].flatMap { $0 }
                ),
                ReportPage(
                    name: "IntegrityChecks",
                    sections: [
                        appInfoReporter.technicalSections(for: appInfo),
                        appFilesReporter.reportSections(forAppAt: appURL, info: appInfo),
                        ].flatMap { $0 }
                ),
                ],
            attachments: appFilesReporter.attachments(forAppAt: appURL, info: appInfo)
        )
    }
}

