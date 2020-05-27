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
        let checkinDate = Date()
        let statusState: StatusState = .symptomatic(StatusState.Symptomatic(
            symptoms: [.temperature],
            startDate: startDate,
            checkinDate: checkinDate
        ))

        let encoded = try encoder.encode(statusState)
        let decoded = try decoder.decode(StatusState.self, from: encoded)

        XCTAssertEqual(decoded, statusState)
    }

    func testCodableExposed() throws {
         let startDate = Date()
         let statusState: StatusState = .exposed(StatusState.Exposed(startDate: startDate))

         let encoded = try encoder.encode(statusState)
         let decoded = try decoder.decode(StatusState.self, from: encoded)

         XCTAssertEqual(decoded, statusState)
     }

    func testCodableUnxposed() throws {
         let statusState: StatusState = .unexposed(StatusState.Unexposed())

         let encoded = try encoder.encode(statusState)
         let decoded = try decoder.decode(StatusState.self, from: encoded)

         XCTAssertEqual(decoded, statusState)
     }

    func testCheckinDateMathBeforeSeven() {
        let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 6))!
        let checkinDate = StatusState.Symptomatic.nextCheckin(from: startDate, afterDays: 7)

        XCTAssertEqual(
            checkinDate,
            Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 8, hour: 7))!
        )
    }

    func testCheckinDateMathAfterSeven() {
        let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 8))!
        let checkinDate = StatusState.Symptomatic.nextCheckin(from: startDate, afterDays: 7)

        XCTAssertEqual(
            checkinDate,
            Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 8, hour: 7))!
        )
    }

    func testExposedExpiresAfterFourteenDays() {
        let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 14, hour: 7))!
        let exposed = StatusState.Exposed(startDate: startDate)

        XCTAssertEqual(
            exposed.expiryDate,
            Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 28, hour: 7))!
        )
    }
    
    func testPositiveTestResultChecksInAfterSevenDays() {
        let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 14, hour: 7))!
        let positiveTestResult = StatusState.PositiveTestResult(symptoms: [], startDate: startDate)

        XCTAssertEqual(
            positiveTestResult.expiryDate,
            Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 21, hour: 7))!
        )
    }

}
