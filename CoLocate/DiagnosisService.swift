//
//  DiagnosisService.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

enum Diagnosis: Int {
    case unknown, notInfected, infected, potential
}

class DiagnosisService {
    
    static func clear() {
        UserDefaults.standard.removeObject(forKey: diagnosisKey)
    }
    
    static var shared = DiagnosisService()

    static let diagnosisKey = "diagnosisKey"
    
    weak var delegate: DiagnosisServiceDelegate?
    
    var currentDiagnosis: Diagnosis {
        
        // This force unwrap is deliberate, we should never store an unknown rawValue
        // and I want to fail fast if we somehow do. Note integer(forKey:) returns 0
        // if the key does not exist, which will inflate to .unknown
        return Diagnosis(rawValue: UserDefaults.standard.integer(forKey: DiagnosisService.diagnosisKey))!
    }
    
    func recordDiagnosis(_ diagnosis: Diagnosis) {
        UserDefaults.standard.set(diagnosis.rawValue, forKey: DiagnosisService.diagnosisKey)
        delegate?.diagnosisService(self, didRecordDiagnosis: diagnosis)
    }

    func clear() {
        UserDefaults.standard.set(Diagnosis.unknown.rawValue, forKey: DiagnosisService.diagnosisKey)
    }
    
}

protocol DiagnosisServiceDelegate: NSObject {
    func diagnosisService(_ diagnosisService: DiagnosisService, didRecordDiagnosis diagnosis: Diagnosis)
}
