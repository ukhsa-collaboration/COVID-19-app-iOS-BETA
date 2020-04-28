import XCTest

extension XCUIElement {
    var hasKeyboardFocus: Bool {
        value(forKey: "hasKeyboardFocus") as! Bool
    }
    
    var stringValue: String {
        (value as? String) ?? ""
    }
    
    var intValue: Int {
        Int(stringValue) ?? 0
    }
    
    var boolValue: Bool {
        intValue > 0
    }
    
    var disappearance: XCTestExpectation {
        let doesNotExist = NSPredicate(format: "exists == false")
        return XCTNSPredicateExpectation(predicate: doesNotExist, object: self)
    }
}
