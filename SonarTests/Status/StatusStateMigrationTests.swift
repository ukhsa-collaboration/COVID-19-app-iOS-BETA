//
//  StatusStateMigrationTests.swift
//  SonarTests
//
//  Created by NHSX on 5/11/20.
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

        XCTAssertEqual(state, .ok(StatusState.Ok()))
    }

    func testOnlyExposed() {
        var state = migration.migrate(
            diagnosis: nil,
            potentiallyExposedOn: dateSentinel
        )
        XCTAssertEqual(state, .exposed(StatusState.Exposed(startDate: dateSentinel)))

        // 2020.04.14
        currentDate = Calendar.current.date(byAdding: .day, value: 13, to: dateSentinel)!
        state = migration.migrate(
            diagnosis: nil,
            potentiallyExposedOn: dateSentinel
        )
        XCTAssertEqual(state, .exposed(StatusState.Exposed(startDate: dateSentinel)))

        // 2020.04.15
        currentDate = Calendar.current.date(byAdding: .day, value: 14, to: dateSentinel)!
        state = migration.migrate(
            diagnosis: nil,
            potentiallyExposedOn: dateSentinel
        )
        XCTAssertEqual(state, .ok(StatusState.Ok()))
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
        XCTAssertEqual(state, .ok(StatusState.Ok()))

        state = migration.migrate(
            diagnosis: SelfDiagnosis(
                type: .initial,
                symptoms: [],
                startDate: dateSentinel
            ),
            potentiallyExposedOn: dateSentinel
        )
        XCTAssertEqual(state, .ok(StatusState.Ok()))

        state = migration.migrate(
            diagnosis: SelfDiagnosis(
                type: .subsequent,
                symptoms: [],
                startDate: dateSentinel
            ),
            potentiallyExposedOn: nil
        )

        XCTAssertEqual(state, .ok(StatusState.Ok()))

        state = migration.migrate(
            diagnosis: SelfDiagnosis(
                type: .subsequent,
                symptoms: [],
                startDate: dateSentinel
            ),
            potentiallyExposedOn: dateSentinel
        )

        XCTAssertEqual(state, .ok(StatusState.Ok()))
    }

    func testSymptomaticUnexpiredAndNotPotentiallyExposed() {
        let expiryDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 2, hour: 7))!
        let diagnosis = SelfDiagnosis(
            type: .initial,
            symptoms: [.temperature],
            startDate: dateSentinel, // 2020.04.01
            expiryDate: expiryDate   // 2020.04.02
        )

        currentDate = Calendar.current.date(byAdding: .second, value: -1, to: diagnosis.expiryDate)!
        let state = migration.migrate(
            diagnosis: diagnosis,
            potentiallyExposedOn: nil
        )

        let checkinDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 8, hour: 7))!
        let symptomatic: StatusState = .symptomatic(StatusState.Symptomatic(
            symptoms: [.temperature],
            startDate: diagnosis.startDate,
            checkinDate: checkinDate
        ))
        XCTAssertEqual(state, symptomatic)
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
        let symptomatic: StatusState = .symptomatic(StatusState.Symptomatic(
            symptoms: [.temperature],
            startDate: diagnosis.startDate,
            checkinDate: expiryDate
        ))
        XCTAssertEqual(state, symptomatic)
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

        let checkinDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 8, hour: 7))!
        let symptomatic: StatusState = .symptomatic(StatusState.Symptomatic(
            symptoms: [.temperature],
            startDate: diagnosis.startDate,
            checkinDate: checkinDate
        ))
        XCTAssertEqual(state, symptomatic)
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

        let symptomatic: StatusState = .symptomatic(StatusState.Symptomatic(
            symptoms: [.temperature],
            startDate: diagnosis.startDate,
            checkinDate: diagnosis.expiryDate
        ))
        XCTAssertEqual(state, symptomatic)
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

        let symptomatic: StatusState = .symptomatic(StatusState.Symptomatic(
            symptoms: [.temperature],
            startDate: diagnosis.startDate,
            checkinDate: diagnosis.expiryDate
        ))
        XCTAssertEqual(state, symptomatic)
    }

}
