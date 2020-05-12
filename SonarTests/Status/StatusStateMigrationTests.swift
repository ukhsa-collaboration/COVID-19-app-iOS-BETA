//
//  StatusStateMigrationTests.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class StatusStateMigrationTests: XCTestCase {

    var migration: StatusStateMigration!

    var dateSentinel: Date!
    var currentDate: Date!
    var dateProvider: (() -> Date)!

    override func setUp() {
        super.setUp()

        dateProvider = { self.currentDate }

        migration = StatusStateMigration(dateProvider: dateProvider)

        dateSentinel = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1))!
        currentDate = dateSentinel
    }

    func testDefaultsToOk() {
        let state = migration.migrate(
            diagnosis: nil,
            potentiallyExposedOn: nil
        )

        XCTAssertEqual(state, .ok)
    }

    func testOnlyExposed() {
        var state = migration.migrate(
            diagnosis: nil,
            potentiallyExposedOn: dateSentinel
        )
        XCTAssertEqual(state, .exposed(StatusState.Exposed(exposureDate: dateSentinel)))

        // 2020.04.14
        currentDate = Calendar.current.date(byAdding: .day, value: 13, to: dateSentinel)!
        state = migration.migrate(
            diagnosis: nil,
            potentiallyExposedOn: dateSentinel
        )
        XCTAssertEqual(state, .exposed(StatusState.Exposed(exposureDate: dateSentinel)))

        // 2020.04.15
        currentDate = Calendar.current.date(byAdding: .day, value: 14, to: dateSentinel)!
        state = migration.migrate(
            diagnosis: nil,
            potentiallyExposedOn: dateSentinel
        )
        XCTAssertEqual(state, .ok)
    }

    // These should be impossible states to be in
    func testSymptomaticNoSymptoms() {
        var state = migration.migrate(
            diagnosis: SelfDiagnosis(
                type: .initial,
                symptoms: [],
                startDate: dateSentinel
            ),
            potentiallyExposedOn: nil
        )
        XCTAssertEqual(state, .ok)

        state = migration.migrate(
            diagnosis: SelfDiagnosis(
                type: .initial,
                symptoms: [],
                startDate: dateSentinel
            ),
            potentiallyExposedOn: dateSentinel
        )
        XCTAssertEqual(state, .ok)

        state = migration.migrate(
            diagnosis: SelfDiagnosis(
                type: .subsequent,
                symptoms: [],
                startDate: dateSentinel
            ),
            potentiallyExposedOn: nil
        )

        XCTAssertEqual(state, .ok)

        state = migration.migrate(
            diagnosis: SelfDiagnosis(
                type: .subsequent,
                symptoms: [],
                startDate: dateSentinel
            ),
            potentiallyExposedOn: dateSentinel
        )

        XCTAssertEqual(state, .ok)
    }

    func testSymptomaticUnexpiredAndNotPotentiallyExposed() {
        let expiryDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 2, hour: 7))!
        let diagnosis = SelfDiagnosis(
            type: .initial,
            symptoms: [.temperature],
            startDate: dateSentinel, // 2020.04.01
            expiryDate:expiryDate    // 2020.04.02
        )

        currentDate = Calendar.current.date(byAdding: .second, value: -1, to: diagnosis.expiryDate)!
        let state = migration.migrate(
            diagnosis: diagnosis,
            potentiallyExposedOn: nil
        )

        XCTAssertEqual(state, .symptomatic(StatusState.Symptomatic(symptoms: [.temperature], expiryDate: diagnosis.expiryDate)))
    }

    func testSymptomaticInitialExpiredAndNotPotentiallyExposed() {
        let expiryDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 2, hour: 7))!
        let diagnosis = SelfDiagnosis(
            type: .initial,
            symptoms: [.temperature],
            startDate: dateSentinel, // 2020.04.01
            expiryDate: expiryDate   // 2020.04.02
        )

        currentDate = Calendar.current.date(byAdding: .second, value: 1, to: diagnosis.expiryDate)!
        let state = migration.migrate(
            diagnosis: diagnosis,
            potentiallyExposedOn: nil
        )

        // 2020.04.02
        XCTAssertEqual(state, .checkin(StatusState.Checkin(symptoms: [.temperature], checkinDate: expiryDate)))
    }

    func testInitialSymptomaticTakesPrecedenceOverExposed() {
        let diagnosis = SelfDiagnosis(
            type: .initial,
            symptoms: [.temperature],
            startDate: dateSentinel
        )

        currentDate = Calendar.current.date(byAdding: .day, value: -1, to: diagnosis.expiryDate)!
        let state = migration.migrate(
            diagnosis: diagnosis,
            potentiallyExposedOn: dateSentinel
        )

        XCTAssertEqual(state, .symptomatic(StatusState.Symptomatic(symptoms: [.temperature], expiryDate: diagnosis.expiryDate)))
    }

    func testSubsequentSymptomaticPreExpiry() {
        let expiryDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 2, hour: 7))!
        let diagnosis = SelfDiagnosis(
            type: .subsequent,
            symptoms: [.temperature],
            startDate: dateSentinel,
            expiryDate: expiryDate
        )

        currentDate = Calendar.current.date(byAdding: .second, value: -1, to: diagnosis.expiryDate)!
        let state = migration.migrate(
            diagnosis: diagnosis,
            potentiallyExposedOn: nil
        )

        XCTAssertEqual(state, .checkin(StatusState.Checkin(symptoms: [.temperature], checkinDate: diagnosis.expiryDate)))
    }

    func testSubsequentSymptomaticPostExpiry() {
        let expiryDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 2, hour: 7))!
        let diagnosis = SelfDiagnosis(
            type: .subsequent,
            symptoms: [.temperature],
            startDate: dateSentinel,
            expiryDate: expiryDate
        )

        currentDate = Calendar.current.date(byAdding: .second, value: 1, to: diagnosis.expiryDate)!
        let state = migration.migrate(
            diagnosis: diagnosis,
            potentiallyExposedOn: nil
        )

        XCTAssertEqual(state, .checkin(StatusState.Checkin(symptoms: [.temperature], checkinDate: diagnosis.expiryDate)))
    }

}
