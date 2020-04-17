
import Foundation

extension String {

    func matches(_ pattern: String) -> Bool {
        return range(of: "^\(pattern)$", options: .regularExpression, range: nil, locale: nil) != nil
    }

}
