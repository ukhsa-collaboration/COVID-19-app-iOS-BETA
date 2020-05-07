//
//  SelfDiagnosis.swift
//  Sonar
//
//  Created by NHSX on 4/16/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

enum SelfDiagnosisType: String, Codable {
    case initial
    case subsequent
}

enum Symptom: String, Codable {
    case temperature, cough
}

struct SelfDiagnosis: Codable, Equatable {
    let type: SelfDiagnosisType
    let symptoms: Set<Symptom>
    let startDate: Date
    var expiryDate: Date = Date()
    
    var isAffected: Bool {
        !symptoms.isEmpty
    }
    
    var hasExpired: Bool {
        return Date() > expiryDate
    }
    
    func expiresIn(days: Int) -> Date {
        return expiresIn(days: days, timeZone: TimeZone.autoupdatingCurrent)
    }
    
    func expiresIn(days: Int, timeZone: TimeZone) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        return calendar.nextDate(
            after: Date(timeInterval: Double((days - 1) * 24 * 60 * 60), since: startDate),
            matching: DateComponents(hour: 7),
            matchingPolicy: .strict
        ) ?? Date()
    }
}

extension SelfDiagnosis {
    init(type: SelfDiagnosisType, symptoms: Set<Symptom>, startDate: Date, daysToLive: Int) {
        self.init(type: type, symptoms: symptoms, startDate: startDate, daysToLive: daysToLive, timeZone: TimeZone.autoupdatingCurrent)
    }
    
    init(type: SelfDiagnosisType, symptoms: Set<Symptom>, startDate: Date, daysToLive: Int, timeZone: TimeZone) {
        self.type = type
        self.symptoms = symptoms
        self.startDate = startDate
        self.expiryDate = expiresIn(days: daysToLive, timeZone: timeZone)
    }
}
