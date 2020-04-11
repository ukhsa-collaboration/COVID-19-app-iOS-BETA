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

    func testDiagnosisRawValueZeroIsUnknown() {
        let persistence = Persistence()
        XCTAssertNil(persistence.diagnosis)
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
        XCTAssertNil(diagnosis)
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
        let secureBroadcastRotationKeyStorage = SecureBroadcastRotationKeyStorage.shared
        let persistence = Persistence(secureRegistrationStorage: secureRegistrationStorage,
                                      secureBroadcastRotationKeyStorage: secureBroadcastRotationKeyStorage)

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

    func testPartialPostcodeIsPersisted() {
        let p1 = Persistence()
        let p2 = Persistence()
        
        p1.partialPostcode = nil
        XCTAssertNil(p2.partialPostcode)
        
        p1.partialPostcode = "9810"
        XCTAssertEqual(p2.partialPostcode, "9810")
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
