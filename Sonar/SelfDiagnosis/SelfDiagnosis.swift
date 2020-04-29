//
//  SelfDiagnosis.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct SelfDiagnosis: Codable, Equatable {
    let symptoms: Set<Symptom>
    let startDate: Date
    var expiryDate: Date

    init(symptoms: Set<Symptom>, startDate: Date, expiryDate: Date = Date()) {
        self.symptoms = symptoms
        self.startDate = startDate
        self.expiryDate = expiryDate
    }
    
    mutating func expiresIn(days: Int) {
        let daysInterval = Double((days - 1) * 24 * 60 * 60)
        self.expiryDate = Calendar.current.nextDate(
            after: Date(timeInterval: daysInterval, since: startDate),
            matching: DateComponents(hour: 7),
            matchingPolicy: .strict
        ) ?? Date()
    }
    
    func hasExpired() -> Bool {
        return Date() > expiryDate
    }

    var isAffected: Bool { !symptoms.isEmpty }
}

enum Symptom: String, Codable {
    case temperature, cough
}
