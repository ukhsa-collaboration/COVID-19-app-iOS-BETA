//
//  StatusStateTests.swift
//  SonarTests
//
//  Created by NHSX on 5/11/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class StatusStateTests: XCTestCase {

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    func testCodableOk() throws {
        let statusState: StatusState = .ok(StatusState.Ok())

        let encoded = try encoder.encode(statusState)
        let decoded = try decoder.decode(StatusState.self, from: encoded)

        XCTAssertEqual(decoded, statusState)
    }

    func testCodableSymptomatic() throws {
        let startDate = Date()
        let statusState: StatusState = .symptomatic(StatusState.Symptomatic(symptoms: [.temperature], startDate: startDate))

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

    func testSymptomaticExpiryBeforeSeven() {
        let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 6))!
        let symptomatic = StatusState.Symptomatic(symptoms: [.cough], startDate: startDate)

        XCTAssertEqual(
            symptomatic.expiryDate,
            Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 8, hour: 7))!
        )
    }

    func testSymptomaticExpiryAfterSeven() {
        let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 8))!
        let symptomatic = StatusState.Symptomatic(symptoms: [.cough], startDate: startDate)

        XCTAssertEqual(
            symptomatic.expiryDate,
            Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 8, hour: 7))!
        )
    }

    func testExposedExpiresAfterFourteenDays() {
        let exposureDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 14, hour: 7))!
        let exposed = StatusState.Exposed(exposureDate: exposureDate)

        XCTAssertEqual(
            exposed.expiryDate,
            Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 28, hour: 7))!
        )
    }

}
