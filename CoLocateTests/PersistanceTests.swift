//
//  PersistanceTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class PersistanceTests: XCTestCase {
    
    override func setUp() {
        super.setUp()

        for key in Persistance.Keys.allCases {
            UserDefaults.standard.removeObject(forKey: key.rawValue)
        }
    }

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
}

class PersistanceDelegateDouble: NSObject, PersistanceDelegate {
    var recordedDiagnosis: Diagnosis?
    
    func persistance(_ persistance: Persistance, didRecordDiagnosis diagnosis: Diagnosis) {
        recordedDiagnosis = diagnosis
    }
}
