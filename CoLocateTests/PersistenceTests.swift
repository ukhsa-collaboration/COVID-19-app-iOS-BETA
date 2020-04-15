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
        XCTAssertNil(persistence.selfDiagnosis)
    }

    func testDiagnosisIsPersisted() {
        let service = Persistence()
        service.selfDiagnosis = .notInfected

        let diagnosis = Persistence().selfDiagnosis
        XCTAssertEqual(diagnosis, SelfDiagnosis.notInfected)
    }

    func testDiagnosisIsUnknownWhenDefaultsReset() {
        let service = Persistence()
        service.selfDiagnosis = .infected

        let appDomain = Bundle.main.bundleIdentifier
        UserDefaults.standard.removePersistentDomain(forName: appDomain!)

        let diagnosis = service.selfDiagnosis
        XCTAssertNil(diagnosis)
    }
    
    
    func testRegistrationIsPassedToSecureRegistrationStorage() throws {
        let secureRegistrationStorage = SecureRegistrationStorage()
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
    var recordedRegistration: Registration?
    func persistence(_ persistence: Persistence, didUpdateRegistration registration: Registration) {
        recordedRegistration = registration
    }
}
