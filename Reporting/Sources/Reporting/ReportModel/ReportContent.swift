import Foundation

protocol ReportContent {
    var markdownBody: String { get }
}

extension String: ReportContent {
    
    var markdownBody: String {
        return self
    }
    
}
