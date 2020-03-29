//
//  DiagnosisServiceTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class DiagnosisServiceTests: XCTestCase {
    
    override func setUp() {
        super.setUp()

        DiagnosisService.clear()
    }

    // Ensure when UserDefaults.integer(forKey: ) doesn't find anything, it translates to .unknown
    func testDiagnosisRawValueZeroIsUnknown() {
        XCTAssertEqual(Diagnosis(rawValue: 0), Diagnosis.unknown)
    }

    func testDiagnosisIsPersisted() {
        let service = DiagnosisService()
        service.recordDiagnosis(Diagnosis.notInfected)

        let diagnosis = DiagnosisService().currentDiagnosis
        XCTAssertEqual(diagnosis, Diagnosis.notInfected)
    }

    func testDiagnosisIsUnknownWhenDefaultsReset() {
        let service = DiagnosisService()
        service.recordDiagnosis(Diagnosis.infected)

        let appDomain = Bundle.main.bundleIdentifier
        UserDefaults.standard.removePersistentDomain(forName: appDomain!)

        let diagnosis = service.currentDiagnosis
        XCTAssertEqual(diagnosis, Diagnosis.unknown)
    }
    
    func testDiagnosisIsPassedToDelegate() {
        let delegate = DiagnosisServiceDelegateDouble()
        let service = DiagnosisService()
        service.delegate = delegate
        
        service.recordDiagnosis(.notInfected)
        
        XCTAssertEqual(delegate.recordedDiagnosis, .notInfected)
    }
}

class DiagnosisServiceDelegateDouble: NSObject, DiagnosisServiceDelegate {
    var recordedDiagnosis: Diagnosis?
    
    func diagnosisService(_ diagnosisService: DiagnosisService, didRecordDiagnosis diagnosis: Diagnosis) {
        recordedDiagnosis = diagnosis
    }
}
