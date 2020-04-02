//
//  PersistenceTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class PersistenceTests: TestCase {

    // Ensure when UserDefaults.integer(forKey: ) doesn't find anything, it translates to .unknown
    func testDiagnosisRawValueZeroIsUnknown() {
        XCTAssertEqual(Diagnosis(rawValue: 0), Diagnosis.unknown)
    }

    func testDiagnosisIsPersisted() {
        let service = Persistence()
        service.diagnosis = .notInfected

        let diagnosis = Persistence().diagnosis
        XCTAssertEqual(diagnosis, Diagnosis.notInfected)
    }

    func testDiagnosisIsUnknownWhenDefaultsReset() {
        let service = Persistence()
        service.diagnosis = .infected

        let appDomain = Bundle.main.bundleIdentifier
        UserDefaults.standard.removePersistentDomain(forName: appDomain!)

        let diagnosis = service.diagnosis
        XCTAssertEqual(diagnosis, Diagnosis.unknown)
    }
    
    func testDiagnosisIsPassedToDelegate() {
        let delegate = PersistenceDelegateDouble()
        let service = Persistence()
        service.delegate = delegate
        
        service.diagnosis = .notInfected
        
        XCTAssertEqual(delegate.recordedDiagnosis, .notInfected)
    }

    func testRegistrationIsPassedToSecureRegistrationStorage() throws {
        let secureRegistrationStorage = SecureRegistrationStorage.shared
        let persistence = Persistence(secureRegistrationStorage: secureRegistrationStorage)

        XCTAssertNil(persistence.registration)

        let id = UUID()
        let secretKey = "secret key".data(using: .utf8)!
        let registration = Registration(id: id, secretKey: secretKey)
        persistence.registration = registration

        XCTAssertEqual(try secureRegistrationStorage.get(), registration)
        XCTAssertEqual(persistence.registration, registration)
    }

    func testRegistrationUpdatesTheDelegate() {
        let delegate = PersistenceDelegateDouble()
        let persistence = Persistence()
        persistence.delegate = delegate

        let id = UUID()
        let secretKey = "secret key".data(using: .utf8)!
        let registration = Registration(id: id, secretKey: secretKey)
        persistence.registration = registration

        XCTAssertEqual(delegate.recordedRegistration, registration)
    }

}

class PersistenceDelegateDouble: NSObject, PersistenceDelegate {
    var recordedDiagnosis: Diagnosis?
    func persistence(_ persistence: Persistence, didRecordDiagnosis diagnosis: Diagnosis) {
        recordedDiagnosis = diagnosis
    }

    var recordedRegistration: Registration?
    func persistence(_ persistence: Persistence, didUpdateRegistration registration: Registration) {
        recordedRegistration = registration
    }
}
