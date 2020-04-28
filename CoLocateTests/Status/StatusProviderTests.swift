//
//  StatusProviderTests.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class StatusProviderTests: XCTestCase {

    var persisting: PersistenceDouble!
    var currentDate: Date!
    var provider: StatusProvider!

    override func setUp() {
        super.setUp()

        persisting = PersistenceDouble()
        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1))!
        provider = StatusProvider(
            persisting: persisting,
            currentDateProvider: { self.currentDate }
        )
    }

    func testDefault() {
        XCTAssertEqual(provider.status, .blue)
    }

    func testPotentiallyExposed() {
        persisting.potentiallyExposed = Date()

        XCTAssertEqual(provider.status, .amber)
    }

    func testSelfDiagnosedWithSymptoms() {
        persisting.selfDiagnosis = SelfDiagnosis(
            symptoms: [.cough],
            startDate: Date()
        )

        XCTAssertEqual(provider.status, .red)
    }

    func testPotentiallyExposedLasts14Days() {
        persisting.potentiallyExposed = currentDate // 04.01
        XCTAssertEqual(provider.status, .amber)

        advanceCurrentDate(by: 13) // 04.14
        XCTAssertEqual(provider.status, .amber)

        advanceCurrentDate(by: 1) // 04.15
        XCTAssertEqual(provider.status, .blue)
    }

    func testRedTakesPrecedenceOverAmber() {
        persisting.potentiallyExposed = currentDate // 04.01
        XCTAssertEqual(provider.status, .amber)

        advanceCurrentDate(by: 1)
        persisting.selfDiagnosis = SelfDiagnosis(
            symptoms: [.cough],
            startDate: Date()
        )
        XCTAssertEqual(provider.status, .red)
    }

    func testAmberThenRedReturnsToBlue() {
        let startDate: Date = currentDate
        persisting.potentiallyExposed = currentDate // 04.01
        XCTAssertEqual(provider.status, .amber)

        advanceCurrentDate(by: 1)
        persisting.selfDiagnosis = SelfDiagnosis(
            symptoms: [.cough],
            startDate: startDate
        )
        XCTAssertEqual(provider.status, .red)

        advanceCurrentDate(by: 1)
        persisting.selfDiagnosis = SelfDiagnosis(
            symptoms: [],
            startDate: startDate
        )
        XCTAssertEqual(provider.status, .blue)
    }

    private func advanceCurrentDate(by days: Int) {
        currentDate = Calendar.current.date(
            byAdding: .day,
            value: days,
            to: currentDate
        )
    }

}
