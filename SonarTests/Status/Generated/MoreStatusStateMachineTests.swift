//
//  MoreStatusStateMachineTests.swift
//  SonarTests
//
//  Created by NHSX on 5/11/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class MoreStatusStateMachineTests: XCTestCase {

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

    func testK_ExposedThenSymptomaticWithinFirstWeek() throws {

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
            self.machine.exposed(on: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposed(let exposed) = self.machine.state else {
                XCTFail("Expected state to be exposed, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposed.expiryDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 3))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 2))!
            try machine.selfDiagnose(symptoms: [.temperature], startDate: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposedSymptomatic(let exposedSymptomatic) = self.machine.state else {
                XCTFail("Expected state to be exposedSymptomatic, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposedSymptomatic.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15))!
        machine.tick()
        do {
            machine.checkin(symptoms: [.temperature])
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 16, hour: 7))!
            guard case .symptomatic(let symptomatic) = self.machine.state else {
                XCTFail("Expected state to be symptomatic, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(symptomatic.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 16))!
        machine.tick()
        do {
            machine.checkin(symptoms: [.temperature])
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 17, hour: 7))!
            guard case .symptomatic(let symptomatic) = self.machine.state else {
                XCTFail("Expected state to be symptomatic, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(symptomatic.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 17))!
        machine.tick()
        do {
            machine.checkin(symptoms: [.cough])
        }

        do {
            XCTAssertEqual(self.machine.state, .ok(StatusState.Ok()))
        }

    }

    func testC_ExposedThenTestPositiveTwiceWithinFirstWeek() throws {

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 2))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
            self.machine.exposed(on: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposed(let exposed) = self.machine.state else {
                XCTFail("Expected state to be exposed, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposed.expiryDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 4))!
        machine.tick()
        do {
            let testDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 2))!
            let testResult = TestResult(
                result: .positive,
                testTimestamp: testDate,
                type: nil,
                acknowledgementUrl: nil
            )
            self.machine.received(testResult)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 9, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

        do {
            XCTAssertEqual(self.drawerMailbox.receive(), .positiveTestResult)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 7))!
        machine.tick()
        do {
            let testDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 5))!
            let testResult = TestResult(
                result: .positive,
                testTimestamp: testDate,
                type: nil,
                acknowledgementUrl: nil
            )
            self.machine.received(testResult)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 9, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

        do {
            XCTAssertEqual(self.drawerMailbox.receive(), .positiveTestResult)
        }

        do {
            machine.checkin(symptoms: [.cough])
        }

        do {
            XCTAssertEqual(self.machine.state, .ok(StatusState.Ok()))
        }

    }

    func testF_ExposedThenIsolationEndsThenTestPositive() throws {

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 2))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
            self.machine.exposed(on: startDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 16))!
        machine.tick()
        do {
            XCTAssertEqual(self.machine.state, .ok(StatusState.Ok()))
        }

        do {
            XCTAssertEqual(self.drawerMailbox.receive(), .unexposed)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 17))!
        machine.tick()
        do {
            let testDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 16))!
            let testResult = TestResult(
                result: .positive,
                testTimestamp: testDate,
                type: nil,
                acknowledgementUrl: nil
            )
            self.machine.received(testResult)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 23))!
        machine.tick()
        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 23, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

        do {
            machine.checkin(symptoms: [.cough])
        }

        do {
            XCTAssertEqual(self.machine.state, .ok(StatusState.Ok()))
        }

    }

    func testE_ExposedThenTestPositiveTwiceWithinAfterWeek() throws {

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 2))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
            self.machine.exposed(on: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposed(let exposed) = self.machine.state else {
                XCTFail("Expected state to be exposed, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposed.expiryDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 11))!
        machine.tick()
        do {
            let testDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 10))!
            let testResult = TestResult(
                result: .positive,
                testTimestamp: testDate,
                type: nil,
                acknowledgementUrl: nil
            )
            self.machine.received(testResult)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 17, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

        do {
            XCTAssertEqual(self.drawerMailbox.receive(), .positiveTestResult)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 13))!
        machine.tick()
        do {
            let testDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 12))!
            let testResult = TestResult(
                result: .positive,
                testTimestamp: testDate,
                type: nil,
                acknowledgementUrl: nil
            )
            self.machine.received(testResult)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 17, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

        do {
            XCTAssertEqual(self.drawerMailbox.receive(), .positiveTestResult)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 17))!
        machine.tick()
        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 17, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

        do {
            machine.checkin(symptoms: [.cough])
        }

        do {
            XCTAssertEqual(self.machine.state, .ok(StatusState.Ok()))
        }

    }

    func testR_ExposedThenSymptomaticAfterFirstWeekThenTestNegativeAfterExposureWindowEnds() throws {

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
            self.machine.exposed(on: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposed(let exposed) = self.machine.state else {
                XCTFail("Expected state to be exposed, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposed.expiryDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 9))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 8))!
            try machine.selfDiagnose(symptoms: [.temperature], startDate: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposedSymptomatic(let exposedSymptomatic) = self.machine.state else {
                XCTFail("Expected state to be exposedSymptomatic, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposedSymptomatic.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 16))!
        machine.tick()
        do {
            let testDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 14))!
            let testResult = TestResult(
                result: .negative,
                testTimestamp: testDate,
                type: nil,
                acknowledgementUrl: nil
            )
            self.machine.received(testResult)
        }

        do {
            XCTAssertEqual(self.machine.state, .ok(StatusState.Ok()))
        }

    }

    func testI_ExposedThenGetTestResultsFromBeforeExposure() throws {

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
            self.machine.exposed(on: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposed(let exposed) = self.machine.state else {
                XCTFail("Expected state to be exposed, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposed.expiryDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 2))!
        machine.tick()
        do {
            let testDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 27))!
            let testResult = TestResult(
                result: .positive,
                testTimestamp: testDate,
                type: nil,
                acknowledgementUrl: nil
            )
            self.machine.received(testResult)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 4, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 5))!
        machine.tick()
        do {
            machine.checkin(symptoms: [.cough])
        }

        do {
            XCTAssertEqual(self.machine.state, .ok(StatusState.Ok()))
        }

    }

    func testExposedThenSymptomaticAfterFirstWeekThenTestNegativeBeforeExposureWindowEnds() throws {

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
            self.machine.exposed(on: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposed(let exposed) = self.machine.state else {
                XCTFail("Expected state to be exposed, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposed.expiryDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 9))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 8))!
            try machine.selfDiagnose(symptoms: [.temperature], startDate: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposedSymptomatic(let exposedSymptomatic) = self.machine.state else {
                XCTFail("Expected state to be exposedSymptomatic, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposedSymptomatic.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 14))!
        machine.tick()
        do {
            let testDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 13))!
            let testResult = TestResult(
                result: .negative,
                testTimestamp: testDate,
                type: nil,
                acknowledgementUrl: nil
            )
            self.machine.received(testResult)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposed(let exposed) = self.machine.state else {
                XCTFail("Expected state to be exposed, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposed.expiryDate, endDate)
        }

    }

    func testA_Exposed() throws {

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 2))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
            self.machine.exposed(on: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposed(let exposed) = self.machine.state else {
                XCTFail("Expected state to be exposed, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposed.expiryDate, endDate)
        }

        do {
            XCTAssertNil(self.drawerMailbox.receive())
        }

        do {
            let request = try XCTUnwrap(self.userNotificationCenter.requests.first)
            XCTAssertEqual(request.identifier, "adviceChangedNotificationIdentifier")
            self.userNotificationCenter.requests.removeFirst()
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15))!
        machine.tick()
        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposed(let exposed) = self.machine.state else {
                XCTFail("Expected state to be exposed, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposed.expiryDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 16))!
        machine.tick()
        do {
            XCTAssertEqual(self.machine.state, .ok(StatusState.Ok()))
        }

        do {
            XCTAssertEqual(self.drawerMailbox.receive(), .unexposed)
        }

    }

    func testD_ExposedThenTestPositiveAfterFirstWeek() throws {

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 2))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
            self.machine.exposed(on: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposed(let exposed) = self.machine.state else {
                XCTFail("Expected state to be exposed, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposed.expiryDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 11))!
        machine.tick()
        do {
            let testDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 10))!
            let testResult = TestResult(
                result: .positive,
                testTimestamp: testDate,
                type: nil,
                acknowledgementUrl: nil
            )
            self.machine.received(testResult)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 17, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 17))!
        machine.tick()
        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 17, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

        do {
            machine.checkin(symptoms: [.cough])
        }

        do {
            XCTAssertEqual(self.machine.state, .ok(StatusState.Ok()))
        }

    }

    func testExposedThenSymptomaticWithinFirstWeekThenTestNegative() throws {

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
            self.machine.exposed(on: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposed(let exposed) = self.machine.state else {
                XCTFail("Expected state to be exposed, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposed.expiryDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 3))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 2))!
            try machine.selfDiagnose(symptoms: [.temperature], startDate: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposedSymptomatic(let exposedSymptomatic) = self.machine.state else {
                XCTFail("Expected state to be exposedSymptomatic, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposedSymptomatic.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 5))!
        machine.tick()
        do {
            let testDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 4))!
            let testResult = TestResult(
                result: .negative,
                testTimestamp: testDate,
                type: nil,
                acknowledgementUrl: nil
            )
            self.machine.received(testResult)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposed(let exposed) = self.machine.state else {
                XCTFail("Expected state to be exposed, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposed.expiryDate, endDate)
        }

    }

    func testTestPositiveThenTestNegative() throws {

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 2))!
        machine.tick()
        do {
            let testDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
            let testResult = TestResult(
                result: .positive,
                testTimestamp: testDate,
                type: nil,
                acknowledgementUrl: nil
            )
            self.machine.received(testResult)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 8, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 4))!
        machine.tick()
        do {
            let testDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 3))!
            let testResult = TestResult(
                result: .negative,
                testTimestamp: testDate,
                type: nil,
                acknowledgementUrl: nil
            )
            self.machine.received(testResult)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 8, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

    }

    func testExposedThenTestPositiveThenPositiveExpiresButStillFeverThenTestNegativeBeforeExposureWindowEnds() throws {

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
            self.machine.exposed(on: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposed(let exposed) = self.machine.state else {
                XCTFail("Expected state to be exposed, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposed.expiryDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 3))!
        machine.tick()
        do {
            let testDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 2))!
            let testResult = TestResult(
                result: .positive,
                testTimestamp: testDate,
                type: nil,
                acknowledgementUrl: nil
            )
            self.machine.received(testResult)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 9, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 9))!
        machine.tick()
        do {
            machine.checkin(symptoms: [.temperature])
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 10, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 11))!
        machine.tick()
        do {
            let testDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 10))!
            let testResult = TestResult(
                result: .negative,
                testTimestamp: testDate,
                type: nil,
                acknowledgementUrl: nil
            )
            self.machine.received(testResult)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 10, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

    }

    func testExposedThenTestNegative() throws {

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
            self.machine.exposed(on: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposed(let exposed) = self.machine.state else {
                XCTFail("Expected state to be exposed, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposed.expiryDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 5))!
        machine.tick()
        do {
            let testDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 4))!
            let testResult = TestResult(
                result: .negative,
                testTimestamp: testDate,
                type: nil,
                acknowledgementUrl: nil
            )
            self.machine.received(testResult)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposed(let exposed) = self.machine.state else {
                XCTFail("Expected state to be exposed, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposed.expiryDate, endDate)
        }

    }

    func testG_ExposedThenIsolationEndsThenTestPositiveFromBeforeIsolationEnded() throws {

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 2))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
            self.machine.exposed(on: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposed(let exposed) = self.machine.state else {
                XCTFail("Expected state to be exposed, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposed.expiryDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 17))!
        machine.tick()
        do {
            let testDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 14))!
            let testResult = TestResult(
                result: .positive,
                testTimestamp: testDate,
                type: nil,
                acknowledgementUrl: nil
            )
            self.machine.received(testResult)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 21, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 21))!
        machine.tick()
        do {
            machine.checkin(symptoms: [.cough])
        }

        do {
            XCTAssertEqual(self.machine.state, .ok(StatusState.Ok()))
        }

    }

    func testN_ExposedThenSymptomaticWithinFirstWeekThenTestPositiveThenTestPositiveNearEndOfIsolation() throws {

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
            self.machine.exposed(on: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposed(let exposed) = self.machine.state else {
                XCTFail("Expected state to be exposed, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposed.expiryDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 6))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 5))!
            try machine.selfDiagnose(symptoms: [.temperature], startDate: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposedSymptomatic(let exposedSymptomatic) = self.machine.state else {
                XCTFail("Expected state to be exposedSymptomatic, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposedSymptomatic.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 10))!
        machine.tick()
        do {
            let testDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 9))!
            let testResult = TestResult(
                result: .positive,
                testTimestamp: testDate,
                type: nil,
                acknowledgementUrl: nil
            )
            self.machine.received(testResult)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 12, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 12))!
        machine.tick()
        do {
            machine.checkin(symptoms: [.temperature])
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 13, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 13))!
        machine.tick()
        do {
            machine.checkin(symptoms: [.cough])
        }

        do {
            XCTAssertEqual(self.machine.state, .ok(StatusState.Ok()))
        }

    }

    func testO_ExposedThenSymptomaticWithinFirstWeekThenTestPositiveAfterSymptomExpiry() throws {

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
            self.machine.exposed(on: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposed(let exposed) = self.machine.state else {
                XCTFail("Expected state to be exposed, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposed.expiryDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 3))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 2))!
            try machine.selfDiagnose(symptoms: [.temperature], startDate: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposedSymptomatic(let exposedSymptomatic) = self.machine.state else {
                XCTFail("Expected state to be exposedSymptomatic, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposedSymptomatic.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 11))!
        machine.tick()
        do {
            let testDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 10))!
            let testResult = TestResult(
                result: .positive,
                testTimestamp: testDate,
                type: nil,
                acknowledgementUrl: nil
            )
            self.machine.received(testResult)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 9, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 11))!
        machine.tick()
        do {
            machine.checkin(symptoms: [.cough])
        }

        do {
            XCTAssertEqual(self.machine.state, .ok(StatusState.Ok()))
        }

    }

    func testExposedThenTestPositiveThenPositiveExpiresButStillFeverThenTestNegativeAfterExposureWindowEnds() throws {

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
            self.machine.exposed(on: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposed(let exposed) = self.machine.state else {
                XCTFail("Expected state to be exposed, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposed.expiryDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 3))!
        machine.tick()
        do {
            let testDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 2))!
            let testResult = TestResult(
                result: .positive,
                testTimestamp: testDate,
                type: nil,
                acknowledgementUrl: nil
            )
            self.machine.received(testResult)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 9, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 9))!
        machine.tick()
        do {
            machine.checkin(symptoms: [.temperature])
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 10, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 17))!
        machine.tick()
        do {
            let testDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 16))!
            let testResult = TestResult(
                result: .negative,
                testTimestamp: testDate,
                type: nil,
                acknowledgementUrl: nil
            )
            self.machine.received(testResult)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 10, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

    }

    func testQ_ExposedThenSymptomaticAfterFirstWeekThenTestPositive() throws {

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
            self.machine.exposed(on: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposed(let exposed) = self.machine.state else {
                XCTFail("Expected state to be exposed, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposed.expiryDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 9))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 8))!
            try machine.selfDiagnose(symptoms: [.temperature], startDate: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposedSymptomatic(let exposedSymptomatic) = self.machine.state else {
                XCTFail("Expected state to be exposedSymptomatic, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposedSymptomatic.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 11))!
        machine.tick()
        do {
            let testDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 10))!
            let testResult = TestResult(
                result: .positive,
                testTimestamp: testDate,
                type: nil,
                acknowledgementUrl: nil
            )
            self.machine.received(testResult)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15))!
        machine.tick()
        do {
            machine.checkin(symptoms: [.temperature])
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 16, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 16))!
        machine.tick()
        do {
            machine.checkin(symptoms: [.cough])
        }

        do {
            XCTAssertEqual(self.machine.state, .ok(StatusState.Ok()))
        }

    }

    func testDefaultToNeutral() throws {

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 2))!
        machine.tick()
        do {
            XCTAssertEqual(self.machine.state, .ok(StatusState.Ok()))
        }

    }

    func testTestPositiveWithExpiryInThePast() throws {

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
        machine.tick()
        do {
            let testDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 23))!
            let testResult = TestResult(
                result: .positive,
                testTimestamp: testDate,
                type: nil,
                acknowledgementUrl: nil
            )
            self.machine.received(testResult)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 30, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

    }

    func testP_ExposedThenSymptomaticFeverAfterFirstWeek() throws {

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
            self.machine.exposed(on: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposed(let exposed) = self.machine.state else {
                XCTFail("Expected state to be exposed, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposed.expiryDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 9))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 8))!
            try machine.selfDiagnose(symptoms: [.temperature], startDate: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposedSymptomatic(let exposedSymptomatic) = self.machine.state else {
                XCTFail("Expected state to be exposedSymptomatic, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposedSymptomatic.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15))!
        machine.tick()
        do {
            machine.checkin(symptoms: [.temperature])
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 16, hour: 7))!
            guard case .symptomatic(let symptomatic) = self.machine.state else {
                XCTFail("Expected state to be symptomatic, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(symptomatic.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 16))!
        machine.tick()
        do {
            machine.checkin(symptoms: [.cough])
        }

        do {
            XCTAssertEqual(self.machine.state, .ok(StatusState.Ok()))
        }

    }

    func testB_ExposedThenTestPositiveWithinFirstWeek() throws {

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 2))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
            self.machine.exposed(on: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposed(let exposed) = self.machine.state else {
                XCTFail("Expected state to be exposed, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposed.expiryDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 4))!
        machine.tick()
        do {
            let testDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 2))!
            let testResult = TestResult(
                result: .positive,
                testTimestamp: testDate,
                type: nil,
                acknowledgementUrl: nil
            )
            self.machine.received(testResult)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 9, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

        do {
            XCTAssertEqual(self.drawerMailbox.receive(), .positiveTestResult)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 9))!
        machine.tick()
        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 9, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

        do {
            machine.checkin(symptoms: [.cough])
        }

        do {
            XCTAssertEqual(self.machine.state, .ok(StatusState.Ok()))
        }

    }

    func testH_TestPositiveThenExposed() throws {

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 27))!
        machine.tick()
        do {
            let testDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 26))!
            let testResult = TestResult(
                result: .positive,
                testTimestamp: testDate,
                type: nil,
                acknowledgementUrl: nil
            )
            self.machine.received(testResult)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 3, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
            self.machine.exposed(on: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 3, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 4))!
        machine.tick()
        do {
            machine.checkin(symptoms: [.cough])
        }

        do {
            XCTAssertEqual(self.machine.state, .ok(StatusState.Ok()))
        }

    }

    func testS_SymptomaticThenTestNegative() throws {

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 2))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
            try machine.selfDiagnose(symptoms: [.temperature], startDate: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 8, hour: 7))!
            guard case .symptomatic(let symptomatic) = self.machine.state else {
                XCTFail("Expected state to be symptomatic, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(symptomatic.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 4))!
        machine.tick()
        do {
            let testDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 3))!
            let testResult = TestResult(
                result: .negative,
                testTimestamp: testDate,
                type: nil,
                acknowledgementUrl: nil
            )
            self.machine.received(testResult)
        }

        do {
            XCTAssertEqual(self.machine.state, .ok(StatusState.Ok()))
        }

    }

    func testL_ExposedThenSymptomaticWithinFirstWeekThenTestPositiveWithinFirst7DaysOfExposure() throws {

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
            self.machine.exposed(on: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposed(let exposed) = self.machine.state else {
                XCTFail("Expected state to be exposed, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposed.expiryDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 3))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 2))!
            try machine.selfDiagnose(symptoms: [.temperature], startDate: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposedSymptomatic(let exposedSymptomatic) = self.machine.state else {
                XCTFail("Expected state to be exposedSymptomatic, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposedSymptomatic.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 5))!
        machine.tick()
        do {
            let testDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 4))!
            let testResult = TestResult(
                result: .positive,
                testTimestamp: testDate,
                type: nil,
                acknowledgementUrl: nil
            )
            self.machine.received(testResult)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 9, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 9))!
        machine.tick()
        do {
            machine.checkin(symptoms: [.temperature])
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 10, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 10))!
        machine.tick()
        do {
            machine.checkin(symptoms: [.cough])
        }

        do {
            XCTAssertEqual(self.machine.state, .ok(StatusState.Ok()))
        }

    }

    func testM_ExposedThenSymptomaticWithinFirstWeekThenTestPositiveThenTestPositiveAgain() throws {

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
            self.machine.exposed(on: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposed(let exposed) = self.machine.state else {
                XCTFail("Expected state to be exposed, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposed.expiryDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 3))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 2))!
            try machine.selfDiagnose(symptoms: [.temperature], startDate: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposedSymptomatic(let exposedSymptomatic) = self.machine.state else {
                XCTFail("Expected state to be exposedSymptomatic, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposedSymptomatic.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 5))!
        machine.tick()
        do {
            let testDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 4))!
            let testResult = TestResult(
                result: .positive,
                testTimestamp: testDate,
                type: nil,
                acknowledgementUrl: nil
            )
            self.machine.received(testResult)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 9, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 10))!
        machine.tick()
        do {
            let testDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 9))!
            let testResult = TestResult(
                result: .positive,
                testTimestamp: testDate,
                type: nil,
                acknowledgementUrl: nil
            )
            self.machine.received(testResult)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 11, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15))!
        machine.tick()
        do {
            machine.checkin(symptoms: [.temperature])
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 16, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 16))!
        machine.tick()
        do {
            machine.checkin(symptoms: [.cough])
        }

        do {
            XCTAssertEqual(self.machine.state, .ok(StatusState.Ok()))
        }

    }

    func testJ_ExposedThenGetTestResultsFromLongBeforeExposure() throws {

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
        machine.tick()
        do {
            let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 1))!
            self.machine.exposed(on: startDate)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 15, hour: 7))!
            guard case .exposed(let exposed) = self.machine.state else {
                XCTFail("Expected state to be exposed, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(exposed.expiryDate, endDate)
        }

        currentDate = Calendar.current.date(from: DateComponents(year: 2020, month: 5, day: 2))!
        machine.tick()
        do {
            let testDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 22))!
            let testResult = TestResult(
                result: .positive,
                testTimestamp: testDate,
                type: nil,
                acknowledgementUrl: nil
            )
            self.machine.received(testResult)
        }

        do {
            let endDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 29, hour: 7))!
            guard case .positive(let positive) = self.machine.state else {
                XCTFail("Expected state to be positive, got \(self.machine.state)")
                return
            }
            XCTAssertEqual(positive.checkinDate, endDate)
        }

    }

}
