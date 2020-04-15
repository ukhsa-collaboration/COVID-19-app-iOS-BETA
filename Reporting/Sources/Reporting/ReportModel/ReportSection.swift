import Foundation

struct ReportSection: ReportContent {
    var title: String
    var content: ReportContent
    
    var markdownBody: String {
        return """
        ### \(title)
        
        \(content.markdownBody)
        """
    }
}
