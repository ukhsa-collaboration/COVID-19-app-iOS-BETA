//
//  DiagnosisServiceTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class DiagnosisServiceTests: XCTestCase {

    // Ensure when UserDefaults.integer(forKey: ) doesn't find anything, it translates to .unknown
    func testDiagnosisRawValueZeroIsUnknown() {
        XCTAssertEqual(Diagnosis(rawValue: 0), Diagnosis.unknown)
    }

}
