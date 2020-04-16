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
    let recordedDate: Date = Date()

    let startDate: Date

    var isAffected: Bool { !symptoms.isEmpty }
}

enum Symptom: String, Codable {
    case temperature, cough
}
