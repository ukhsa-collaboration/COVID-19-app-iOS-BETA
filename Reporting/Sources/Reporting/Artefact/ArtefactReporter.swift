import Foundation

struct ArtefactReporter {
    
    var appURL: URL
    
    var reportFolder: URL

    func run() throws {
        let report = try self.report(for: appURL)
        try report.save(to: reportFolder)
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

