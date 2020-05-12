//
//  StatusStateTests.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class StatusStateTests: XCTestCase {

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    func testCodableOk() throws {
        let statusState: StatusState = .ok

        let encoded = try encoder.encode(statusState)
        let decoded = try decoder.decode(StatusState.self, from: encoded)

        XCTAssertEqual(decoded, statusState)
    }

    func testCodableSymptomatic() throws {
        let expiryDate = Date()
        let statusState: StatusState = .symptomatic(StatusState.Symptomatic(symptoms: [.temperature], expiryDate: expiryDate))

        let encoded = try encoder.encode(statusState)
        let decoded = try decoder.decode(StatusState.self, from: encoded)

        XCTAssertEqual(decoded, statusState)
    }

    func testCodableCheckin() throws {
        let checkinDate = Date()
        let statusState: StatusState = .checkin(StatusState.Checkin(symptoms: [.cough], checkinDate: checkinDate))

        let encoded = try encoder.encode(statusState)
        let decoded = try decoder.decode(StatusState.self, from: encoded)

        XCTAssertEqual(decoded, statusState)
    }

    func testCodableExposed() throws {
         let exposureDate = Date()
         let statusState: StatusState = .exposed(StatusState.Exposed(exposureDate: exposureDate))

         let encoded = try encoder.encode(statusState)
         let decoded = try decoder.decode(StatusState.self, from: encoded)

         XCTAssertEqual(decoded, statusState)
     }

}
