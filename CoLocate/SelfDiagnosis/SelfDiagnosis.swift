//
//  SelfDiagnosis.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct SelfDiagnosis: Codable, Equatable {
    let symptoms: Set<Symptom>
    let startDate: Date
    let expiryDate: Date

    init(symptoms: Set<Symptom>, startDate: Date, expiryDate: Date) {
        self.symptoms = symptoms
        self.startDate = startDate
        self.expiryDate = expiryDate
    }
    
    func hasExpired() -> Bool {
        return Date() > expiryDate
    }

    var isAffected: Bool { !symptoms.isEmpty }
}

enum Symptom: String, Codable {
    case temperature, cough
}
