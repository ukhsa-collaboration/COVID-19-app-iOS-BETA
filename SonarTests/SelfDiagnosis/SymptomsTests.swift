//
//  SymptomsTests.swift
//  SonarTests
//
//  Created by NHSX on 5/19/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class SymptomsTests: XCTestCase {

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    func testEncodingBackwardsCompat() throws {
        let symptoms = Symptoms([.temperature, .cough])
        let encoded = try encoder.encode(symptoms)

        let decoded = try decoder.decode(Set<Symptom>.self, from: encoded)
        XCTAssertEqual(decoded, [.temperature, .cough])
    }

    func testDecodingBackwardsCompat() throws {
        let set: Set<Symptom> = [.temperature, .cough]
        let encoded = try encoder.encode(set)

        let decoded = try decoder.decode(Symptoms.self, from: encoded)

        let symptoms = Symptoms([.temperature, .cough])
        XCTAssertEqual(decoded, symptoms)
    }


}
