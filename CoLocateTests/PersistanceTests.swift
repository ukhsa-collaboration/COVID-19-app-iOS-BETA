//
//  PersistanceTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class PersistanceTests: TestCase {

    // Ensure when UserDefaults.integer(forKey: ) doesn't find anything, it translates to .unknown
    func testDiagnosisRawValueZeroIsUnknown() {
        XCTAssertEqual(Diagnosis(rawValue: 0), Diagnosis.unknown)
    }

    func testDiagnosisIsPersisted() {
        let service = Persistance()
        service.diagnosis = .notInfected

        let diagnosis = Persistance().diagnosis
        XCTAssertEqual(diagnosis, Diagnosis.notInfected)
    }

    func testDiagnosisIsUnknownWhenDefaultsReset() {
        let service = Persistance()
        service.diagnosis = .infected

        let appDomain = Bundle.main.bundleIdentifier
        UserDefaults.standard.removePersistentDomain(forName: appDomain!)

        let diagnosis = service.diagnosis
        XCTAssertEqual(diagnosis, Diagnosis.unknown)
    }
    
    func testDiagnosisIsPassedToDelegate() {
        let delegate = PersistanceDelegateDouble()
        let service = Persistance()
        service.delegate = delegate
        
        service.diagnosis = .notInfected
        
        XCTAssertEqual(delegate.recordedDiagnosis, .notInfected)
    }

    func testRegistrationIsPassedToSecureRegistrationStorage() {
        let secureRegistrationStorage = SecureRegistrationStorage.shared
        let persistance = Persistance(secureRegistrationStorage: secureRegistrationStorage)

        XCTAssertNil(persistance.registration)

        let id = UUID()
        let secretKey = "secret key".data(using: .utf8)!
        let registration = Registration(id: id, secretKey: secretKey)
        persistance.registration = registration

        XCTAssertEqual(try! secureRegistrationStorage.get(), registration)
        XCTAssertEqual(persistance.registration, registration)
    }
}

class PersistanceDelegateDouble: NSObject, PersistanceDelegate {
    var recordedDiagnosis: Diagnosis?
    
    func persistance(_ persistance: Persistance, didRecordDiagnosis diagnosis: Diagnosis) {
        recordedDiagnosis = diagnosis
    }
}
