import Foundation

struct ReportList: ReportContent {
    
    enum Kind {
        case ordered
        case unordered
        
        fileprivate var tag: String {
            switch self {
            case .ordered:
                return "ol"
            case .unordered:
                return "ul"
            }
        }
    }
    
    var kind: Kind
    var items: [ReportContent]
    
    var markdownBody: String {
        let tag = kind.tag
        let listItems = items.lazy.map { "<li>\($0)</li>"}.joined(separator: "")
        
        return "<\(tag)>\(listItems)</\(tag)>"
    }
    
}
