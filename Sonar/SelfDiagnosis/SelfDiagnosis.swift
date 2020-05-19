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

// This class continues to exist to allow migrating old data but is otherwise unused
// see StatusStateMigration.swift
struct SelfDiagnosis: Codable, Equatable {
    let type: SelfDiagnosisType
    let symptoms: Set<Symptom>
    let startDate: Date
    var expiryDate: Date = Date()
}
