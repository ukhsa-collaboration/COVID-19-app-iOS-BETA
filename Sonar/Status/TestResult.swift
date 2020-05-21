//
//  TestResult.swift
//  Sonar
//
//  Created by NHSX on 21/05/2020
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct TestResult: Codable {
    let result: Result
    let testTimestamp: String?
    let type: String?
    let acknowledgementUrl: String?
}

extension TestResult {
    enum Result: String, Codable {
        case positive = "POSITIVE"
        case negative = "NEGATIVE"
        case invalid = "INVALID"
    }
}

extension TestResult.Result {
    var headerText: String? {
        switch self {
        case .positive:
            return "TEST_UPDATE_DRAW_POSITIVE_HEADER".localized
        default:
            assertionFailure("Header text not defined for \(self)")
            return nil
        }
    }
    
    var detailText: String { "TEST_UPDATE_DRAW_DETAIL".localized }
}

