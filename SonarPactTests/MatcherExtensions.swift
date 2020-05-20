//
//  MatcherExtensions.swift
//  SonarPactTests
//
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import PactConsumerSwift

extension Matcher {
    static let uuidRegexp = "[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}"
    
    static func uuid(_ uuid: String) -> [String: Any] {
        return self.term(matcher: uuidRegexp, generate: uuid)
    }
    
    static func uuid() -> [String: Any] {
        return self.uuid(UUID().uuidString)
    }
}
