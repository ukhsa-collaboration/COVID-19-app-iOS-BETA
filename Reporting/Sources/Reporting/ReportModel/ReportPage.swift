import Foundation

struct ReportPage {
    var name: String
    var sections: [ReportSection]
}

extension ReportPage {
    
    func save(in reportFolder: URL) throws {
        let report = sections
            .lazy
            .map { $0.markdownBody }
            .joined(separator: "\n\n")
        
        let reportFile = reportFolder.appendingPathComponent("\(name).md")
        try? FileManager().createDirectory(at: reportFolder, withIntermediateDirectories: true)
        try? report.write(to: reportFile, atomically: true, encoding: .utf8)
    }
    
}
