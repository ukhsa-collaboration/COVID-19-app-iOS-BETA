//
//  TestResult.swift
//  Sonar
//
//  Created by NHSX on 21/05/2020
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct TestResult: Codable {
    let testTimestamp: String?
    let result: ResultType
    let type: String?
    let acknowledgementUrl: String?
}

extension TestResult {
    enum ResultType: String, Codable {
        case positive = "POSITIVE"
        case negative = "NEGATIVE"
        case unclear = "INVALID" // Backend calls this invalid
    }
}

extension TestResult.ResultType {
    var headerText: String { "TEST_UPDATE_DRAW_\(rawValue)_HEADER".localized }
    var detailText: String { "TEST_UPDATE_DRAW_\(rawValue)_DETAIL".localized }
}

