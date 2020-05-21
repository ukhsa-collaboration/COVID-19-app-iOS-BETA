//
//  StatusStateMachineTests.swift
//  SonarTests
//
//  Created by NHSX on 5/11/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class StatusStateMachineTests: XCTestCase {

    var machine: StatusStateMachine!
    var persisting: PersistenceDouble!
    var contactEventsUploader: ContactEventsUploaderDouble!
    var notificationCenter: NotificationCenter!
    var userNotificationCenter: UserNotificationCenterDouble!
    var currentDate: Date!

    override func setUp() {
        persisting = PersistenceDouble()
        contactEventsUploader = ContactEventsUploaderDouble()
        notificationCenter = NotificationCenter()
        userNotificationCenter = UserNotificationCenterDouble()
        currentDate = Date()

        machine = StatusStateMachine(
            persisting: persisting,
            contactEventsUploader: contactEventsUploader,
            notificationCenter: notificationCenter,
            userNotificationCenter: userNotificationCenter,
            dateProvider: { self.currentDate }
        )
    }

    func testDefaultIsOk() {
        XCTAssertEqual(machine.state, .ok(StatusState.Ok()))
    }

    func testPostExposureNotificationOnExposed() throws {
        machine.exposed()

        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.identifier, "adviceChangedNotificationIdentifier")
    }
    
    func testPostPositiveTestResultNotificationOnReceived() throws {
        persisting.statusState = .symptomatic(StatusState.Symptomatic(symptoms: [], startDate: currentDate))
        machine.received(.positive)

        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.content.title, "TEST_RESULT_TITLE".localized)
    }

    func testPostNotificationOnStatusChange() throws {
        var notificationPosted = false
        notificationCenter.addObserver(
            forName: StatusStateMachine.StatusStateChangedNotification,
            object: nil,
            queue: nil
        ) { _ in
            notificationPosted = true
        }

        machine.exposed()
        XCTAssertTrue(notificationPosted)

        notificationPosted = false
        try machine.selfDiagnose(symptoms: [.cough], startDate: currentDate)
        XCTAssertTrue(notificationPosted)
    }

    func testSelfDiagnoseToSymptomatic() throws {
        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 6, hour: 6))!
        persisting.statusState = .ok(StatusState.Ok())

        let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 6))!
        try machine.selfDiagnose(symptoms: [.cough], startDate: startDate)

        XCTAssertEqual(machine.state, .symptomatic(StatusState.Symptomatic(symptoms: [.cough], startDate: startDate)))

        XCTAssertEqual(contactEventsUploader.uploadStartDate, startDate)

        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.identifier, "Diagnosis")
    }

    func testSelfDiagnoseTemperatureAfterSevenDays() throws {
        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 8, hour: 8))!
        persisting.statusState = .ok(StatusState.Ok())

        let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 6))!
        try machine.selfDiagnose(symptoms: [.temperature], startDate: startDate)

        let checkinDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 9, hour: 7))!
        XCTAssertEqual(machine.state, .checkin(StatusState.Checkin(symptoms: [.temperature], checkinDate: checkinDate)))

        XCTAssertEqual(contactEventsUploader.uploadStartDate, startDate)

        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.identifier, "Diagnosis")
    }

    func testSelfDiagnoseCoughAfterSevenDaysIsOk() throws {
        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 8, hour: 8))!
        persisting.statusState = .ok(StatusState.Ok())

        let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 6))!
        try machine.selfDiagnose(symptoms: [.cough], startDate: startDate)

        XCTAssertEqual(machine.state, .ok(StatusState.Ok()))

        XCTAssertEqual(contactEventsUploader.uploadStartDate, startDate)

        XCTAssertNil(userNotificationCenter.requests.first)
    }

    func testExposedToSymptomatic() throws {
        persisting.statusState = .exposed(StatusState.Exposed(startDate: Date()))

        let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 6))!
        try machine.selfDiagnose(symptoms: [.cough], startDate: startDate)

        XCTAssertEqual(machine.state, .symptomatic(StatusState.Symptomatic(symptoms: [.cough], startDate: startDate)))
        XCTAssertEqual(contactEventsUploader.uploadStartDate, startDate)

        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.identifier, "Diagnosis")
    }

    func testTickFromSymptomaticToCheckin() throws {
        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 7))!
        let symptomatic = StatusState.Symptomatic(symptoms: [.cough], startDate: currentDate)
        persisting.statusState = .symptomatic(symptomatic)

        currentDate = Calendar.current.date(byAdding: .hour, value: -1, to: symptomatic.expiryDate)!
        machine.tick()
        XCTAssertTrue(machine.state.isSymptomatic)

        currentDate = Calendar.current.date(byAdding: .hour, value: 1, to: symptomatic.expiryDate)!
        machine.tick()
        guard case .checkin(let checkin) = machine.state else {
            XCTFail()
            return
        }

        XCTAssertEqual(checkin.checkinDate, symptomatic.expiryDate)

        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.identifier, "Diagnosis")
    }

    func testTickWhenExposedBeforeSeven() {
        let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 6))!
        let expiry = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 14, hour: 7))!
        persisting.statusState = .exposed(StatusState.Exposed(startDate: startDate))

        currentDate = Calendar.current.date(byAdding: .hour, value: -1, to: expiry)!
        machine.tick()
        XCTAssertTrue(machine.state.isExposed)

        currentDate = Calendar.current.date(byAdding: .day, value: 1, to: expiry)!
        machine.tick()
        XCTAssertEqual(machine.state, .ok(StatusState.Ok()))
    }

    func testTickWhenExposedAfterSeven() {
        let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 8))!
        let expiry = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 15, hour: 7))!
        persisting.statusState = .exposed(StatusState.Exposed(startDate: startDate))

        currentDate = Calendar.current.date(byAdding: .hour, value: -1, to: expiry)!
        machine.tick()
        XCTAssertTrue(machine.state.isExposed)

        currentDate = Calendar.current.date(byAdding: .day, value: 1, to: expiry)!
        machine.tick()
        XCTAssertEqual(machine.state, .ok(StatusState.Ok()))
    }

    func testCheckinOnlyCough() {
        let checkinAt = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 7))!
        persisting.statusState = .checkin(StatusState.Checkin(symptoms: [.cough], checkinDate: checkinAt))

        currentDate = Calendar.current.date(byAdding: .hour, value: 1, to: checkinAt)!
        machine.checkin(symptoms: [.cough])
        XCTAssertEqual(machine.state, .ok(StatusState.Ok()))

        XCTAssertEqual(userNotificationCenter.removedIdentifiers, ["Diagnosis"])
        XCTAssertNil(userNotificationCenter.requests.first)
    }

    func testCheckinOnlyTemperature() throws {
        let checkinAt = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 7))!
        persisting.statusState = .checkin(StatusState.Checkin(symptoms: [.cough], checkinDate: checkinAt))

        currentDate = Calendar.current.date(byAdding: .hour, value: 1, to: checkinAt)!
        machine.checkin(symptoms: [.temperature])

        let nextCheckin = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 2, hour: 7))!
        XCTAssertEqual(machine.state, .checkin(StatusState.Checkin(symptoms: [.temperature], checkinDate: nextCheckin)))

        XCTAssertEqual(userNotificationCenter.removedIdentifiers, ["Diagnosis"])
        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.identifier, "Diagnosis")
    }

    func testCheckinBothCoughAndTemperature() throws {
        let checkinAt = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 7))!
        persisting.statusState = .checkin(StatusState.Checkin(symptoms: [.cough], checkinDate: checkinAt))

        currentDate = Calendar.current.date(byAdding: .hour, value: 1, to: checkinAt)!
        machine.checkin(symptoms: [.cough, .temperature])

        let nextCheckin = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 2, hour: 7))!
        XCTAssertEqual(machine.state, .checkin(StatusState.Checkin(symptoms: [.cough, .temperature], checkinDate: nextCheckin)))

        XCTAssertEqual(userNotificationCenter.removedIdentifiers, ["Diagnosis"])
        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.identifier, "Diagnosis")
    }

    func testCheckinWithTemperatureAfterMultipleDays() throws {
        let checkinAt = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 7))!
        persisting.statusState = .checkin(StatusState.Checkin(symptoms: [.cough], checkinDate: checkinAt))

        // 2020.04.04
        currentDate = Calendar.current.date(byAdding: .day, value: 3, to: checkinAt)!
        machine.checkin(symptoms: [.temperature])

        let nextCheckin = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 5, hour: 7))!
        XCTAssertEqual(machine.state, .checkin(StatusState.Checkin(symptoms: [.temperature], checkinDate: nextCheckin)))

        XCTAssertEqual(userNotificationCenter.removedIdentifiers, ["Diagnosis"])
        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.identifier, "Diagnosis")
    }

    func testIgnoreExposedWhenSymptomatic() {
        let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1))!
        persisting.statusState = .symptomatic(StatusState.Symptomatic(symptoms: [.cough], startDate: startDate))

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 2))!
        machine.exposed()

        XCTAssertEqual(machine.state, .symptomatic(StatusState.Symptomatic(symptoms: [.cough], startDate: startDate)))
    }

    func testIgnoreExposedWhenCheckingIn() {
        let checkinDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1))!
        persisting.statusState = .checkin(StatusState.Checkin(symptoms: [.temperature], checkinDate: checkinDate))

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 2))!
        machine.exposed()

        XCTAssertEqual(machine.state, .checkin(StatusState.Checkin(symptoms: [.temperature], checkinDate: checkinDate)))
    }

    func testExposedFromOk() throws {
        persisting.statusState = .ok(StatusState.Ok())

        machine.exposed()

        XCTAssertEqual(machine.state, .exposed(StatusState.Exposed(startDate: currentDate)))
    }

    func testExposedAgainAfterUnexposed() throws {
        persisting.statusState = .unexposed(StatusState.Unexposed())

        machine.exposed()

        XCTAssertEqual(machine.state, .exposed(StatusState.Exposed(startDate: currentDate)))
    }

    func testUnexposedAfterExposed() throws {
        persisting.statusState = .exposed(StatusState.Exposed(startDate: Date()))

        machine.unexposed()

        XCTAssertEqual(machine.state, .unexposed(StatusState.Unexposed()))

        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.identifier, "adviceChangedNotificationIdentifier")
    }
}
