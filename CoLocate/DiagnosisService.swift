//
//  DiagnosisService.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

enum Diagnosis: Int {
    case unknown, notInfected, infected
}

class DiagnosisService {
    
    let diagnosisKey = "diagnosisKey"
    
    var currentDiagnosis: Diagnosis {
        
        // This force unwrap is deliberate, we should never store an unknown rawValue
        // and I want to fail fast if we somehow do. Note integer(forKey:) returns 0
        // if the key does not exist, which will inflate to .unknown
        return Diagnosis(rawValue: UserDefaults.standard.integer(forKey: diagnosisKey))!
    }
    
    func recordDiagnosis(_ diagnosis: Diagnosis) {
        UserDefaults.standard.set(diagnosis.rawValue, forKey: diagnosisKey)
    }

}
