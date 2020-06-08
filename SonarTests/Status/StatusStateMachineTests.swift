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
    var drawerMailbox: DrawerMailboxingDouble!
    var notificationCenter: NotificationCenter!
    var userNotificationCenter: UserNotificationCenterDouble!
    var currentDate: Date!

    override func setUp() {
        persisting = PersistenceDouble()
        contactEventsUploader = ContactEventsUploaderDouble()
        drawerMailbox = DrawerMailboxingDouble()
        notificationCenter = NotificationCenter()
        userNotificationCenter = UserNotificationCenterDouble()
        currentDate = Date()

        machine = StatusStateMachine(
            persisting: persisting,
            contactEventsUploader: contactEventsUploader,
            drawerMailbox: drawerMailbox,
            notificationCenter: notificationCenter,
            userNotificationCenter: userNotificationCenter,
            dateProvider: { self.currentDate }
        )
    }

    func testDefaultIsOk() {
        XCTAssertEqual(machine.state, .ok(StatusState.Ok()))
    }

    func testPostExposureNotificationOnExposed() throws {
        machine.exposed(on: currentDate)

        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.identifier, "adviceChangedNotificationIdentifier")
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

        machine.exposed(on: currentDate)
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

        let checkinDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 8, hour: 7))!
        XCTAssertEqual(machine.state, .symptomatic(StatusState.Symptomatic(
            symptoms: [.cough],
            startDate: startDate,
            checkinDate: checkinDate
        )))

        XCTAssertEqual(contactEventsUploader.uploadStartDate, startDate)

        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.identifier, "Diagnosis")

        XCTAssertNil(drawerMailbox.receive())
    }

    func testSelfDiagnoseStraigntIntoCheckinFlow() throws {
        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 10, hour: 6))!
        persisting.statusState = .ok(StatusState.Ok())

        let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 6))!
        try machine.selfDiagnose(symptoms: [.temperature], startDate: startDate)

        let checkinDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 11, hour: 7))!
        XCTAssertEqual(machine.state, .symptomatic(StatusState.Symptomatic(
            symptoms: [.temperature],
            startDate: startDate,
            checkinDate: checkinDate
        )))

        XCTAssertEqual(contactEventsUploader.uploadStartDate, startDate)

        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.identifier, "Diagnosis")

        XCTAssertNil(drawerMailbox.receive())
    }

    func testSelfDiagnoseTemperatureAfterSevenDays() throws {
        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 8, hour: 8))!
        persisting.statusState = .ok(StatusState.Ok())

        let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 6))!
        try machine.selfDiagnose(symptoms: [.temperature], startDate: startDate)

        let checkinDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 9, hour: 7))!
        XCTAssertEqual(machine.state, .symptomatic(StatusState.Symptomatic(
            symptoms: [.temperature],
            startDate: startDate,
            checkinDate: checkinDate
        )))

        XCTAssertEqual(contactEventsUploader.uploadStartDate, startDate)

        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.identifier, "Diagnosis")

        XCTAssertNil(drawerMailbox.receive())
    }

    func testSelfDiagnoseCoughAfterSevenDaysIsOk() throws {
        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 8, hour: 8))!
        persisting.statusState = .ok(StatusState.Ok())

        let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 6))!
        try machine.selfDiagnose(symptoms: [.cough], startDate: startDate)

        XCTAssertEqual(machine.state, .ok(StatusState.Ok()))

        XCTAssertEqual(contactEventsUploader.uploadStartDate, startDate)

        XCTAssertNil(userNotificationCenter.requests.first)
        XCTAssertEqual(drawerMailbox.receive(), .symptomsButNotSymptomatic)
    }

    func testSelfDiagnoseAnosmiaAfterSevenDaysIsOk() throws {
        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 8, hour: 8))!
        persisting.statusState = .ok(StatusState.Ok())

        let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 6))!
        try machine.selfDiagnose(symptoms: [.anosmia], startDate: startDate)

        XCTAssertEqual(machine.state, .ok(StatusState.Ok()))

        XCTAssertEqual(contactEventsUploader.uploadStartDate, startDate)

        XCTAssertNil(userNotificationCenter.requests.first)
        XCTAssertEqual(drawerMailbox.receive(), .symptomsButNotSymptomatic)
    }

    func testSelfDiagnoseFromExposedWithSymptomaticExpiry() throws {
        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 13))!

        let exposureDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1))!
        persisting.statusState = .exposed(StatusState.Exposed(startDate: exposureDate))

        let selfDiagnosisDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 12, hour: 6))!
        try machine.selfDiagnose(symptoms: [.cough], startDate: selfDiagnosisDate)

        let checkinDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 19, hour: 7))!
        XCTAssertEqual(machine.state, .exposedSymptomatic(StatusState.ExposedSymptomatic(
            symptoms: [.cough],
            startDate: exposureDate,
            checkinDate: checkinDate
        )))
        XCTAssertEqual(contactEventsUploader.uploadStartDate, selfDiagnosisDate)

        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.identifier, "Diagnosis")

        XCTAssertNil(drawerMailbox.receive())
    }

    func testSelfDiagnoseWhileExposedWithSymptomsButNotSymptomatic() throws {
        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 1, day: 17))!

        let exposureDate = Calendar.current.date(from: DateComponents(year: 2020, month: 1, day: 1))! // expires day 15
        persisting.statusState = .exposed(StatusState.Exposed(startDate: exposureDate))

        let selfDiagnosisDate = Calendar.current.date(from: DateComponents(year: 2020, month: 1, day: 9))! // expires day 16
        try machine.selfDiagnose(symptoms: [.cough], startDate: selfDiagnosisDate)

        XCTAssertEqual(machine.state, .exposed(StatusState.Exposed(startDate: exposureDate)))
        XCTAssertEqual(contactEventsUploader.uploadStartDate, selfDiagnosisDate)

        XCTAssertNil(drawerMailbox.receive())
    }
    
    func testSelfDiagnoseWhilstExposedWithSymptomsCheckinDateAfterExposureExpiryDate() throws {
        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 1, day: 11))!

        let exposureDate = Calendar.current.date(from: DateComponents(year: 2020, month: 1, day: 1))! // expires day 15
        persisting.statusState = .exposed(StatusState.Exposed(startDate: exposureDate))

        let selfDiagnosisDate = Calendar.current.date(from: DateComponents(year: 2020, month: 1, day: 9))! // expires day 16
        try machine.selfDiagnose(symptoms: [.temperature], startDate: selfDiagnosisDate)
        
        let symptomCheckinDate = Calendar.current.date(from: DateComponents(year: 2020, month: 1, day: 16, hour: 7))!
        XCTAssertEqual(machine.state, .exposedSymptomatic(StatusState.ExposedSymptomatic(
            symptoms: [.temperature],
            startDate: exposureDate,
            checkinDate: symptomCheckinDate
        )))
        
        XCTAssertEqual(contactEventsUploader.uploadStartDate, selfDiagnosisDate)

        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.identifier, "Diagnosis")

        XCTAssertNil(drawerMailbox.receive())
    }
    
    func testSelfDiagnoseWhilstExposedWithSymptomsCheckinDateBeforeExposureExpiryDate() throws {
        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 1, day: 11))!

        let exposureDate = Calendar.current.date(from: DateComponents(year: 2020, month: 1, day: 1))! // expires day 15
        persisting.statusState = .exposed(StatusState.Exposed(startDate: exposureDate))

        let selfDiagnosisDate = Calendar.current.date(from: DateComponents(year: 2020, month: 1, day: 7))! // expires day 14
        try machine.selfDiagnose(symptoms: [.temperature], startDate: selfDiagnosisDate)
        
        let exposureExpiryDate = Calendar.current.date(from: DateComponents(year: 2020, month: 1, day: 15, hour: 7))!
        XCTAssertEqual(machine.state, .exposedSymptomatic(StatusState.ExposedSymptomatic(
            symptoms: [.temperature],
            startDate: exposureDate,
            checkinDate: exposureExpiryDate
        )))
        
        XCTAssertEqual(contactEventsUploader.uploadStartDate, selfDiagnosisDate)

        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.identifier, "Diagnosis")

        XCTAssertNil(drawerMailbox.receive())
    }

    func testSelfDiagnoseWhileExposedAfterFourteenDays() {
        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 20, hour: 6))!
        let exposureStartDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 6, hour: 6))!
        
        persisting.statusState = .exposedSymptomatic(StatusState.ExposedSymptomatic(symptoms: nil, startDate: exposureStartDate, checkinDate: currentDate))
        machine.checkin(symptoms: [.temperature])
        
        let newCheckinDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 21, hour: 7))!
        XCTAssertEqual(machine.state, .symptomatic(StatusState.Symptomatic(
            symptoms: [.temperature],
            startDate: exposureStartDate,
            checkinDate: newCheckinDate
        )))
    }

    func testExposedSymptomaticToOkAfterFourteenDays() {
        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 20, hour: 6))!
        let exposureStartDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 6, hour: 6))!
        
        persisting.statusState = .exposedSymptomatic(StatusState.ExposedSymptomatic(symptoms: nil, startDate: exposureStartDate, checkinDate: currentDate))
        machine.checkin(symptoms: [.cough])
        
        XCTAssertEqual(machine.state, .ok(StatusState.Ok()))
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
        let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 3, day: 31, hour: 7))!
        let checkinAt = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 7))!
        persisting.statusState = .symptomatic(StatusState.Symptomatic(
            symptoms: [.cough],
            startDate: startDate,
            checkinDate: checkinAt
        ))

        currentDate = Calendar.current.date(byAdding: .hour, value: 1, to: checkinAt)!
        machine.checkin(symptoms: [.cough])
        XCTAssertEqual(machine.state, .ok(StatusState.Ok()))

        XCTAssertEqual(userNotificationCenter.removedIdentifiers, ["Diagnosis"])
        XCTAssertNil(userNotificationCenter.requests.first)
        XCTAssertEqual(drawerMailbox.receive(), .symptomsButNotSymptomatic)
    }

    func testCheckinOnlyTemperature() throws {
        let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 3, day: 31, hour: 7))!
        let checkinAt = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 7))!
        persisting.statusState = .symptomatic(StatusState.Symptomatic(
            symptoms: [.cough],
            startDate: startDate,
            checkinDate: checkinAt
        ))

        currentDate = Calendar.current.date(byAdding: .hour, value: 1, to: checkinAt)!
        machine.checkin(symptoms: [.temperature])

        let nextCheckin = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 2, hour: 7))!
        XCTAssertEqual(machine.state, .symptomatic(StatusState.Symptomatic(
            symptoms: [.temperature],
            startDate: startDate,
            checkinDate: nextCheckin
        )))

        XCTAssertEqual(userNotificationCenter.removedIdentifiers, ["Diagnosis"])
        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.identifier, "Diagnosis")
        XCTAssertNil(drawerMailbox.receive())
    }

    func testCheckinBothCoughAndTemperature() throws {
        let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 3, day: 31, hour: 7))!
        let checkinAt = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 7))!
        persisting.statusState = .symptomatic(StatusState.Symptomatic(
            symptoms: [.cough],
            startDate: startDate,
            checkinDate: checkinAt
        ))

        currentDate = Calendar.current.date(byAdding: .hour, value: 1, to: checkinAt)!
        machine.checkin(symptoms: [.cough, .temperature])

        let nextCheckin = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 2, hour: 7))!
        XCTAssertEqual(machine.state, .symptomatic(StatusState.Symptomatic(
            symptoms: [.cough, .temperature],
            startDate: startDate,
            checkinDate: nextCheckin
        )))

        XCTAssertEqual(userNotificationCenter.removedIdentifiers, ["Diagnosis"])
        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.identifier, "Diagnosis")
        XCTAssertNil(drawerMailbox.receive())
    }

    func testCheckinWithTemperatureAfterMultipleDays() throws {
        let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 3, day: 31, hour: 7))!
        let checkinAt = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1, hour: 7))!
        persisting.statusState = .symptomatic(StatusState.Symptomatic(
            symptoms: [.cough],
            startDate: startDate,
            checkinDate: checkinAt
        ))

        // 2020.04.04
        currentDate = Calendar.current.date(byAdding: .day, value: 3, to: checkinAt)!
        machine.checkin(symptoms: [.temperature])

        let nextCheckin = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 5, hour: 7))!
        XCTAssertEqual(machine.state, .symptomatic(StatusState.Symptomatic(
            symptoms: [.temperature],
            startDate: startDate,
            checkinDate: nextCheckin
        )))

        XCTAssertEqual(userNotificationCenter.removedIdentifiers, ["Diagnosis"])
        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.identifier, "Diagnosis")
        XCTAssertNil(drawerMailbox.receive())
    }

    // This can happen when you get a positive test result while symptomatic
    func testCheckinBeforeTheCheckinDate() throws {
        let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 3, day: 31))!
        let checkinAt = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 5, hour: 7))!
        persisting.statusState = .symptomatic(StatusState.Symptomatic(
            symptoms: [.cough],
            startDate: startDate,
            checkinDate: checkinAt
        ))

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 3))!
        machine.checkin(symptoms: [.temperature])

        let nextCheckin = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 4, hour: 7))!
        XCTAssertEqual(machine.state, .symptomatic(StatusState.Symptomatic(
            symptoms: [.temperature],
            startDate: startDate,
            checkinDate: nextCheckin
        )))

        XCTAssertEqual(userNotificationCenter.removedIdentifiers, ["Diagnosis"])
        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.identifier, "Diagnosis")
        XCTAssertNil(drawerMailbox.receive())
    }

    func testIgnoreExposedWhenSymptomatic() {
        let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1))!
        let checkinAt = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 15, hour: 7))!
        persisting.statusState = .symptomatic(StatusState.Symptomatic(
            symptoms: [.cough],
            startDate: startDate,
            checkinDate: checkinAt
        ))

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 2))!
        machine.exposed(on: currentDate)

        XCTAssertEqual(machine.state, .symptomatic(StatusState.Symptomatic(
            symptoms: [.cough],
            startDate: startDate,
            checkinDate: checkinAt
        )))
    }

    func testIgnoreExposedWhenCheckingIn() {
        let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 3, day: 31, hour: 7))!
        let checkinDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 1))!
        persisting.statusState = .symptomatic(StatusState.Symptomatic(
            symptoms: [.temperature],
            startDate: startDate,
            checkinDate: checkinDate
        ))

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 2))!
        machine.exposed(on: currentDate)

        XCTAssertEqual(machine.state, .symptomatic(StatusState.Symptomatic(
            symptoms: [.temperature],
            startDate: startDate,
            checkinDate: checkinDate
        )))

    }

    func testExposedFromOk() throws {
        persisting.statusState = .ok(StatusState.Ok())

        machine.exposed(on: currentDate)

        XCTAssertEqual(machine.state, .exposed(StatusState.Exposed(startDate: currentDate)))
    }

    func testUnexposedAfterExposed() throws {
        persisting.statusState = .exposed(StatusState.Exposed(startDate: Date()))

        machine.unexposed()

        XCTAssertEqual(drawerMailbox.receive(), .unexposed)
        XCTAssertEqual(machine.state, .ok(StatusState.Ok()))

        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.identifier, "adviceChangedNotificationIdentifier")
    }

    func testReceivedPositiveTestResultFromOk() throws {
        persisting.statusState = .ok(StatusState.Ok())

        let testTimestamp = Calendar.current.date(from: DateComponents(month: 5, day: 10))!
        let positiveTestResult = TestResult(
            result: .positive,
            testTimestamp: testTimestamp,
            type: nil,
            acknowledgementUrl: nil
        )

        machine.received(positiveTestResult)
        
        let endDate = StatusState.PositiveTestResult.firstCheckin(from: testTimestamp)
        XCTAssertEqual(machine.state, .positiveTestResult(StatusState.PositiveTestResult(
            checkinDate: endDate, symptoms: nil, startDate: testTimestamp)
        ))
        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.identifier, "testResult.arrived")
        XCTAssertEqual(request.content.title, "TEST_RESULT_TITLE".localized)
        XCTAssertEqual(drawerMailbox.receive(), .positiveTestResult)
    }

    func testReceivedPositiveTestResultFromExposed() throws {
        persisting.statusState = .exposed(StatusState.Exposed(startDate: currentDate))

        let testTimestamp = Calendar.current.date(from: DateComponents(month: 5, day: 10))!
        let positiveTestResult = TestResult(
            result: .positive,
            testTimestamp: testTimestamp,
            type: nil,
            acknowledgementUrl: nil
        )

        machine.received(positiveTestResult)
        let endDate = StatusState.PositiveTestResult.firstCheckin(from: testTimestamp)
        XCTAssertEqual(machine.state, .positiveTestResult(StatusState.PositiveTestResult(
            checkinDate: endDate, symptoms: nil, startDate: testTimestamp)
        ))
        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.identifier, "testResult.arrived")
        XCTAssertEqual(request.content.title, "TEST_RESULT_TITLE".localized)
        XCTAssertEqual(drawerMailbox.receive(), .positiveTestResult)
    }


    func testReceivedPositiveTestResultWithEarlierSymptomatic() throws {
        let startDate = Calendar.current.date(byAdding: .day, value: -5, to: currentDate)!
        let checkinDate = StatusState.Symptomatic.firstCheckin(from: startDate)
        persisting.statusState = .symptomatic(StatusState.Symptomatic(
            symptoms: [.cough], startDate: startDate, checkinDate: checkinDate
        ))

        let testTimestamp = Calendar.current.date(byAdding: .day, value: -2, to: currentDate)!
        let positiveTestResult = TestResult(
            result: .positive,
            testTimestamp: testTimestamp,
            type: nil,
            acknowledgementUrl: nil
        )

        machine.received(positiveTestResult)
        XCTAssertEqual(machine.state, .positiveTestResult(StatusState.PositiveTestResult(
            checkinDate: checkinDate, symptoms: [.cough], startDate: testTimestamp)
        ))
        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.identifier, "testResult.arrived")
        XCTAssertEqual(request.content.title, "TEST_RESULT_TITLE".localized)
        XCTAssertEqual(drawerMailbox.receive(), .positiveTestResult)
    }

    func testReceivedPositiveTestResultWithLaterSymptomatic() throws {
        let startDate = Calendar.current.date(byAdding: .day, value: -3, to: currentDate)!
        let testTimestamp = Calendar.current.date(byAdding: .day, value: -5, to: currentDate)!
        let checkinDate = StatusState.Symptomatic.firstCheckin(from: testTimestamp)
        persisting.statusState = .symptomatic(StatusState.Symptomatic(
            symptoms: [.temperature], startDate: startDate, checkinDate: checkinDate
        ))
        let positiveTestResult = TestResult(
            result: .positive,
            testTimestamp: testTimestamp,
            type: nil,
            acknowledgementUrl: nil
        )

        machine.received(positiveTestResult)

        XCTAssertEqual(machine.state, .positiveTestResult(StatusState.PositiveTestResult(
            checkinDate: checkinDate, symptoms: [.temperature], startDate: testTimestamp)
        ))
        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.identifier, "testResult.arrived")
        XCTAssertEqual(request.content.title, "TEST_RESULT_TITLE".localized)
        XCTAssertEqual(drawerMailbox.receive(), .positiveTestResult)
    }

    func testReceivedUnclearTestResultFromOk() throws {
        persisting.statusState = .ok(StatusState.Ok())

        let testTimestamp = Calendar.current.date(from: DateComponents(month: 5, day: 10))!
        let positiveTestResult = TestResult(
            result: .unclear,
            testTimestamp: testTimestamp,
            type: nil,
            acknowledgementUrl: nil
        )

        machine.received(positiveTestResult)

        XCTAssertEqual(machine.state, .ok(StatusState.Ok()))
        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.identifier, "testResult.arrived")
        XCTAssertEqual(request.content.title, "TEST_RESULT_TITLE".localized)
        XCTAssertEqual(drawerMailbox.receive(), .unclearTestResult)
    }

    func testReceivedUnclearTestResultFromExposed() throws {
        persisting.statusState = .exposed(StatusState.Exposed(startDate: currentDate))

        let testTimestamp = Calendar.current.date(from: DateComponents(month: 5, day: 10))!
        let positiveTestResult = TestResult(
            result: .unclear,
            testTimestamp: testTimestamp,
            type: nil,
            acknowledgementUrl: nil
        )

        machine.received(positiveTestResult)

        XCTAssertEqual(machine.state, .exposed(StatusState.Exposed(startDate: currentDate)))
        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.identifier, "testResult.arrived")
        XCTAssertEqual(request.content.title, "TEST_RESULT_TITLE".localized)
        XCTAssertEqual(drawerMailbox.receive(), .unclearTestResult)
    }

    func testReceivedUnclearTestResultWhenSymptomatic() throws {
        let startDate = Calendar.current.date(byAdding: .day, value: -5, to: currentDate)!
        let checkinDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        let symptomatic = StatusState.Symptomatic(
            symptoms: [.cough], startDate: startDate, checkinDate: checkinDate
        )
        persisting.statusState = .symptomatic(symptomatic)

        let testTimestamp = Calendar.current.date(byAdding: .day, value: -2, to: currentDate)!
        let positiveTestResult = TestResult(
            result: .unclear,
            testTimestamp: testTimestamp,
            type: nil,
            acknowledgementUrl: nil
        )

        machine.received(positiveTestResult)

        XCTAssertEqual(machine.state, .symptomatic(symptomatic))
        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.identifier, "testResult.arrived")
        XCTAssertEqual(request.content.title, "TEST_RESULT_TITLE".localized)
        XCTAssertEqual(drawerMailbox.receive(), .unclearTestResult)
    }

    func testReceivedNegativeTestResultWhenOk() throws {
        persisting.statusState = .ok(StatusState.Ok())

        let testTimestamp = Calendar.current.date(from: DateComponents(month: 5, day: 10))!
        let testResult = TestResult(
            result: .negative,
            testTimestamp: testTimestamp,
            type: nil,
            acknowledgementUrl: nil
        )

        machine.received(testResult)
        XCTAssertEqual(machine.state, .ok(StatusState.Ok()))

        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.identifier, "testResult.arrived")
        XCTAssertEqual(request.content.title, "TEST_RESULT_TITLE".localized)
        XCTAssertEqual(drawerMailbox.receive(), .negativeTestResult)
    }

    func testReceivedNegativeTestResultWhenExposedSymptomatic() throws {
        let exposedDate: Date = currentDate
        persisting.statusState = .exposedSymptomatic(StatusState.ExposedSymptomatic(
            symptoms: nil, startDate: exposedDate, checkinDate: Date()
        ))

        let testTimestamp = Calendar.current.date(from: DateComponents(month: 5, day: 10))!
        let testResult = TestResult(
            result: .negative,
            testTimestamp: testTimestamp,
            type: nil,
            acknowledgementUrl: nil
        )

        machine.received(testResult)
        XCTAssertEqual(machine.state, .exposed(StatusState.Exposed(startDate: exposedDate)))

        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.content.title, "TEST_RESULT_TITLE".localized)
        XCTAssertEqual(request.identifier, "testResult.arrived")
        XCTAssertEqual(drawerMailbox.receive(), .negativeTestResult)
    }

    func testReceivedNegativeTestResultWhenExposedBefore() throws {
        let exposedDate = Calendar.current.date(from: DateComponents(month: 5, day: 10))!
        let testDate = Calendar.current.date(from: DateComponents(month: 5, day: 11))!

        persisting.statusState = .exposed(StatusState.Exposed(startDate: exposedDate))
        let testResult = TestResult(
            result: .negative,
            testTimestamp: testDate,
            type: nil,
            acknowledgementUrl: nil
        )

        machine.received(testResult)
        XCTAssertEqual(machine.state, .exposed(StatusState.Exposed(startDate: exposedDate)))

        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.content.title, "TEST_RESULT_TITLE".localized)
        XCTAssertEqual(request.identifier, "testResult.arrived")
        XCTAssertEqual(drawerMailbox.receive(), .negativeTestResult)
    }

    func testReceivedNegativeTestResultWhenExposedAfter() throws {
        let exposedDate = Calendar.current.date(from: DateComponents(month: 5, day: 12))!
        let testDate = Calendar.current.date(from: DateComponents(month: 5, day: 11))!

        persisting.statusState = .exposed(StatusState.Exposed(startDate: exposedDate))
        let testResult = TestResult(
            result: .negative,
            testTimestamp: testDate,
            type: nil,
            acknowledgementUrl: nil
        )

        machine.received(testResult)
        XCTAssertEqual(machine.state, .exposed(StatusState.Exposed(startDate: exposedDate)))

        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.content.title, "TEST_RESULT_TITLE".localized)
        XCTAssertEqual(request.identifier, "testResult.arrived")
        XCTAssertEqual(drawerMailbox.receive(), .negativeTestResult)
    }

    func testReceivedNegativeTestResultWithEarlierSymptomatic() throws {
        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 13))!

        let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 10))!
        let checkinDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 17))!
        let symptomatic = StatusState.Symptomatic(
            symptoms: [.cough], startDate: startDate, checkinDate: checkinDate
        )
        persisting.statusState = .symptomatic(symptomatic)

        let testDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 11))!
        let testResult = TestResult(
            result: .negative,
            testTimestamp: testDate,
            type: nil,
            acknowledgementUrl: nil
        )

        machine.received(testResult)
        XCTAssertEqual(machine.state, .ok(StatusState.Ok()))

        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.content.title, "TEST_RESULT_TITLE".localized)
        XCTAssertEqual(request.identifier, "testResult.arrived")
        XCTAssertEqual(drawerMailbox.receive(), .negativeTestResult)
    }

    func testReceivedNegativeTestResultWithLaterSymptomatic() throws {
        let startDate = Calendar.current.date(from: DateComponents(month: 5, day: 12))!
        let testDate = Calendar.current.date(from: DateComponents(month: 5, day: 11))!

        let checkinDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
        let symptomatic = StatusState.Symptomatic(
            symptoms: [.cough], startDate: startDate, checkinDate: checkinDate
        )
        persisting.statusState = .symptomatic(symptomatic)
        let testResult = TestResult(
            result: .negative,
            testTimestamp: testDate,
            type: nil,
            acknowledgementUrl: nil
        )

        machine.received(testResult)
        XCTAssertEqual(machine.state, .symptomatic(symptomatic))

        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.content.title, "TEST_RESULT_TITLE".localized)
        XCTAssertEqual(request.identifier, "testResult.arrived")
        XCTAssertEqual(drawerMailbox.receive(), .negativeTestResult)
    }

    func testReceivedNegativeTestResultWithEarlierPositiveTest() throws {
        let positiveDate = Calendar.current.date(from: DateComponents(month: 5, day: 10))!
        let testDate = Calendar.current.date(from: DateComponents(month: 6, day: 10))!
        let endDate = StatusState.PositiveTestResult.firstCheckin(from: positiveDate)
        let positiveTestResult = StatusState.positiveTestResult(.init(checkinDate: endDate,
                                                                      symptoms: nil,
                                                                      startDate: positiveDate))
        persisting.statusState = positiveTestResult

        let testResult = TestResult(
            result: .negative,
            testTimestamp: testDate,
            type: nil,
            acknowledgementUrl: nil
        )
        machine.received(testResult)
        XCTAssertEqual(machine.state, positiveTestResult)

        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.content.title, "TEST_RESULT_TITLE".localized)
        XCTAssertEqual(request.identifier, "testResult.arrived")
        XCTAssertEqual(drawerMailbox.receive(), .negativeTestResult)
    }

    func testReceivedNegativeTestResultWithLaterPositiveTest() throws {
        let positiveDate = Calendar.current.date(from: DateComponents(month: 6, day: 10))!
        let testDate = Calendar.current.date(from: DateComponents(month: 5, day: 10))!
        let endDate = StatusState.PositiveTestResult.firstCheckin(from: positiveDate)
        let positive = StatusState.PositiveTestResult(checkinDate: endDate, symptoms: nil, startDate: positiveDate)
        persisting.statusState = .positiveTestResult(positive)

        let testResult = TestResult(
            result: .negative,
            testTimestamp: testDate,
            type: nil,
            acknowledgementUrl: nil
        )
        machine.received(testResult)
        XCTAssertEqual(machine.state, .positiveTestResult(positive))

        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.content.title, "TEST_RESULT_TITLE".localized)
        XCTAssertEqual(request.identifier, "testResult.arrived")
        XCTAssertEqual(drawerMailbox.receive(), .negativeTestResult)
    }
    
    func testSymptomaticToOkCancelsReminderNotification() throws {
        let now = Date()
        persisting.statusState = .symptomatic(StatusState.Symptomatic(symptoms: arbitraryNonEmptySymptoms, startDate: now - 200, checkinDate: now - 100))
        
        switch machine.state {
        case .symptomatic(_):
            break;
        default:
            XCTFail("wrong initial state")
        }
        machine.checkin(symptoms: [])
        XCTAssertEqual(machine.state, .ok(StatusState.Ok()))
        
        XCTAssertEqual(userNotificationCenter.removedIdentifiers, ["Diagnosis"])
    }

    func testSymptomaticToPositiveCancelsReminderNotification() throws {
        let now = Date()
        persisting.statusState = .symptomatic(StatusState.Symptomatic(symptoms: arbitraryNonEmptySymptoms, startDate: now - 200, checkinDate: now - 100))
        
        switch machine.state {
        case .symptomatic(_):
            break;
        default:
            XCTFail("wrong initial state")
        }

        let testResult = TestResult(
            result: .positive,
            testTimestamp: now,
            type: nil,
            acknowledgementUrl: nil
        )
        machine.received(testResult)
        switch machine.state {
        case .positiveTestResult(_):
            break;
        default:
            XCTFail("wrong end state")
        }
        
        XCTAssertEqual(userNotificationCenter.removedIdentifiers, ["Diagnosis"])
    }

    func testSymptomaticToSymptomaticCancelsAndReschedulesNotification() throws {
        let now = Date()
        persisting.statusState = .symptomatic(StatusState.Symptomatic(symptoms: arbitraryNonEmptySymptoms, startDate: now - 200, checkinDate: now - 100))
        
        switch machine.state {
        case .symptomatic(_):
            break;
        default:
            XCTFail("wrong initial state")
        }

        machine.checkin(symptoms: [.temperature])
        switch machine.state {
        case .symptomatic(_):
            break;
        default:
            XCTFail("wrong end state")
        }
        
        XCTAssertEqual(userNotificationCenter.removedIdentifiers, ["Diagnosis"])
        let request = try XCTUnwrap(userNotificationCenter.requests.first)
        XCTAssertEqual(request.identifier, "Diagnosis")
    }
}

private let arbitraryNonEmptySymptoms = Symptoms([.temperature])
