import Foundation

extension Sequence {
    
    func count(where isIncluded: (Element) -> Bool) -> Int {
        self.lazy.filter(isIncluded).count
    }
    
}
