//
//  StatusStateMachineTests.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class StatusStateMachineTests: XCTestCase {

    var machine: StatusStateMachine!
    var persisting: PersistenceDouble!
    var currentDate: Date!

    override func setUp() {
        persisting = PersistenceDouble()
        machine = StatusStateMachine(
            persisting: persisting,
            dateProvider: self.currentDate
        )
    }

    func testDefaultIsOk() {
        XCTAssertEqual(machine.state, .ok)
    }

    func testOkToSymptomaticBeforeSeven() {
        let date = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 6))!
        machine.selfDiagnose(symptoms: [.cough], startDate: date)

        let expires = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 8, hour: 7))!
        XCTAssertEqual(machine.state, .symptomatic(symptoms: [.cough], expires: expires))
    }

    func testOkToSymptomaticAfterSeven() {
        let date = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 8))!
        machine.selfDiagnose(symptoms: [.cough], startDate: date)

        let expires = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 8, hour: 7))!
        XCTAssertEqual(machine.state, .symptomatic(symptoms: [.cough], expires: expires))
    }

    func testTickFromSymptomaticToCheckin() {
        let expiry = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 7))!
        persisting.statusState = .symptomatic(symptoms: [.cough], expires: expiry)

        currentDate = Calendar.current.date(byAdding: .hour, value: -1, to: expiry)!
        machine.tick()
        XCTAssertTrue(machine.state.isSymptomatic)

        currentDate = Calendar.current.date(byAdding: .hour, value: 1, to: expiry)!
        machine.tick()
        guard case .checkin(_, let checkinDate) = machine.state else {
            XCTFail()
            return
        }

        XCTAssertEqual(checkinDate, expiry)
    }

    func testTickWhenExposedBeforeSeven() {
        let exposureDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 6))!
        let expiry = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 14, hour: 7))!
        persisting.statusState = .exposed(on: exposureDate)

        currentDate = Calendar.current.date(byAdding: .hour, value: -1, to: expiry)!
        machine.tick()
        XCTAssertTrue(machine.state.isExposed)

        currentDate = Calendar.current.date(byAdding: .day, value: 1, to: expiry)!
        machine.tick()
        XCTAssertEqual(machine.state, .ok)
    }

    func testTickWhenExposedAfterSeven() {
        let exposureDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 8))!
        let expiry = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 15, hour: 7))!
        persisting.statusState = .exposed(on: exposureDate)

        currentDate = Calendar.current.date(byAdding: .hour, value: -1, to: expiry)!
        machine.tick()
        XCTAssertTrue(machine.state.isExposed)

        currentDate = Calendar.current.date(byAdding: .day, value: 1, to: expiry)!
        machine.tick()
        XCTAssertEqual(machine.state, .ok)
    }

    func testCheckinOnlyCough() {
        let checkinAt = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 7))!
        persisting.statusState = .checkin(symptoms: [.cough], at: checkinAt)

        currentDate = Calendar.current.date(byAdding: .hour, value: 1, to: checkinAt)!
        machine.checkin(symptoms: [.cough])
        XCTAssertEqual(machine.state, .ok)
    }

    func testCheckinOnlyTemperature() {
        let checkinAt = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 7))!
        persisting.statusState = .checkin(symptoms: [.cough], at: checkinAt)

        currentDate = Calendar.current.date(byAdding: .hour, value: 1, to: checkinAt)!
        machine.checkin(symptoms: [.temperature])

        let nextCheckin = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 2, hour: 7))!
        XCTAssertEqual(machine.state, .checkin(symptoms: [.temperature], at: nextCheckin))
    }

    func testCheckinBothCoughAndTemperature() {
        let checkinAt = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 7))!
        persisting.statusState = .checkin(symptoms: [.cough], at: checkinAt)

        currentDate = Calendar.current.date(byAdding: .hour, value: 1, to: checkinAt)!
        machine.checkin(symptoms: [.cough, .temperature])

        let nextCheckin = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 2, hour: 7))!
        XCTAssertEqual(machine.state, .checkin(symptoms: [.cough, .temperature], at: nextCheckin))
    }

    func testCheckinWithTemperatureAfterMultipleDays() {
        let checkinAt = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 7))!
        persisting.statusState = .checkin(symptoms: [.cough], at: checkinAt)

        // 2020.04.04
        currentDate = Calendar.current.date(byAdding: .day, value: 3, to: checkinAt)!
        machine.checkin(symptoms: [.temperature])

        let nextCheckin = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 5, hour: 7))!
        XCTAssertEqual(machine.state, .checkin(symptoms: [.temperature], at: nextCheckin))
    }

    func testIgnoreExposedWhenAlreadyExposed() {
        let exposureDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1))!
        persisting.statusState = .exposed(on: exposureDate)

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 2))!
        machine.exposed()

        XCTAssertEqual(machine.state, .exposed(on: exposureDate))
    }

    func testIgnoreExposedWhenSymptomatic() {
        let expiryDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1))!
        persisting.statusState = .symptomatic(symptoms: [.cough], expires: expiryDate)

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 2))!
        machine.exposed()

        XCTAssertEqual(machine.state, .symptomatic(symptoms: [.cough], expires: expiryDate))
    }

    func testIgnoreExposedWhenCheckingIn() {
        let checkinDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1))!
        persisting.statusState = .checkin(symptoms: [.temperature], at: checkinDate)

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 2))!
        machine.exposed()

        XCTAssertEqual(machine.state, .checkin(symptoms: [.temperature], at: checkinDate))
    }

}
