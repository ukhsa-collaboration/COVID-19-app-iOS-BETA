//
//  SelfDiagnosisTests.swift
//  SonarTests
//
//  Created by NHSX on 06/05/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class SelfDiagnosisTests: XCTestCase {
    func testExpiresAt7amSameDayIfDiagnosisBefore7amFor1DayToLive() throws {
        let timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 60 * 60))
        let startDate = Date(timeIntervalSince1970: 0)
        let expectedDate = Calendar.current.date(byAdding: .hour, value: 6, to: startDate)
        let selfDiagnosis = SelfDiagnosis(type: .initial, symptoms: Set<Symptom>(), startDate: startDate, daysToLive: 1, timeZone: timeZone)
        XCTAssertEqual(selfDiagnosis.expiryDate, expectedDate)
    }
    
    func testExpiresAt7amNextDayIfDiagnosisBefore7amFor1DayToLive() throws {
        let timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 60 * 60))
        let startDate = Date(timeIntervalSince1970: 7 * 60 * 60)
        let expectedDate = Calendar.current.date(byAdding: .hour, value: 23, to: startDate)
        let selfDiagnosis = SelfDiagnosis(type: .initial, symptoms: Set<Symptom>(), startDate: startDate, daysToLive: 1, timeZone: timeZone)
        XCTAssertEqual(selfDiagnosis.expiryDate, expectedDate)
    }
    
    func testNotAffectedIfThereAreNoSymptoms() {
        let selfDiagnosis = SelfDiagnosis(type: .initial, symptoms: Set<Symptom>(), startDate: Date())
        XCTAssertFalse(selfDiagnosis.isAffected)
    }
    
    func testIsAffectedIfThereAreSymptoms() {
        let symptoms: Set = [Symptom.temperature, Symptom.cough]
        let selfDiagnosis = SelfDiagnosis(type: .initial, symptoms: symptoms, startDate: Date())
        XCTAssertTrue(selfDiagnosis.isAffected)
    }
}
