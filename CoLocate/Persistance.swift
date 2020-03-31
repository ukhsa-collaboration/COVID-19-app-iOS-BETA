//
//  Persistance.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

enum Diagnosis: Int, CaseIterable {
    case unknown, notInfected, infected, potential
}

protocol PersistanceDelegate: class {
    func persistance(_ persistance: Persistance, didRecordDiagnosis diagnosis: Diagnosis)
}

class Persistance {

    enum Keys: String, CaseIterable {
        case diagnosis
    }

    static var shared = Persistance()
    
    weak var delegate: PersistanceDelegate?
    
    var diagnosis: Diagnosis {
        get {
            // This force unwrap is deliberate, we should never store an unknown rawValue
            // and I want to fail fast if we somehow do. Note integer(forKey:) returns 0
            // if the key does not exist, which will inflate to .unknown
            return Diagnosis(rawValue: UserDefaults.standard.integer(forKey: Keys.diagnosis.rawValue))!
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Keys.diagnosis.rawValue)
            delegate?.persistance(self, didRecordDiagnosis: diagnosis)
        }
    }

}


