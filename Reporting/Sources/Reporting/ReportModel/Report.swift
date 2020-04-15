import Foundation

struct Report {
    var pages: [ReportPage]
    var attachments: [ReportAttachment]
}

extension Report {
    
    func save(to reportFolder: URL) throws {
        let fileManager = FileManager()
        if fileManager.fileExists(atPath: reportFolder.path) {
            try fileManager.removeItem(at: reportFolder)
        }
        
        try fileManager.createDirectory(at: reportFolder, withIntermediateDirectories: true)
        try pages.forEach {
            try $0.save(in: reportFolder)
        }
        
        if !attachments.isEmpty {
            let attachmentsFolder = reportFolder.appendingPathComponent("Attachments", isDirectory: true)
            try fileManager.createDirectory(at: attachmentsFolder, withIntermediateDirectories: true)
            try attachments.forEach {
                let destination = attachmentsFolder.appendingPathComponent($0.name)
                try fileManager.copyItem(at: $0.source, to: destination)
            }
        }
    }
    
}
