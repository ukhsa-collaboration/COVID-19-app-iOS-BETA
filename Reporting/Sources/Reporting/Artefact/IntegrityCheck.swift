import Foundation

struct IntegrityCheck {
    
    enum Result {
        case passed
        case failed(message: String)
    }
    
    var name: String
    var result: Result
    
    var passed: Bool {
        switch result {
        case .passed:
            return true
        case .failed:
            return false
        }
    }
    
    var errorMessage: String? {
        switch result {
        case .passed:
            return nil
        case .failed(let message):
            return message
        }
    }
}

extension ReportTable where Row == IntegrityCheck {
    
    init(checks: [IntegrityCheck]) {
        self.init(
            rows: checks,
            columns: [
                ReportColumnAdapter(title: "Check", makeContent: { $0.name }),
                ReportColumnAdapter(title: "Passed?", makeContent: { $0.passed ? "✅" : "❌" }),
                ReportColumnAdapter(title: "Notes", makeContent: { $0.errorMessage ?? "" }),
                ]
        )
    }
    
}
