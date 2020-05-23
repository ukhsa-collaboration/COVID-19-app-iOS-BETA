//
//  Symptoms.swift
//  Sonar
//
//  Created by NHSX on 5/19/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

enum Symptom: String, CaseIterable, Codable {
    case temperature, cough, anosmia, sneeze, nausea
}

struct Symptoms: Equatable {
    private var symptoms: Set<Symptom>

    var hasCoronavirusSymptoms: Bool {
        return !symptoms.intersection([.temperature, .cough, .anosmia]).isEmpty
    }

    init(_ symptoms: Set<Symptom>) {
        self.symptoms = symptoms
    }

    func getSymptoms() -> Set<Symptom> {
        return symptoms
    }

    func contains(_ symptom: Symptom) -> Bool {
        return symptoms.contains(symptom)
    }

    mutating func insert(_ symptom: Symptom) {
        symptoms.insert(symptom)
    }

    mutating func remove(_ symptom: Symptom) {
        symptoms.remove(symptom)
    }
}

extension Symptoms: ExpressibleByArrayLiteral {
    typealias ArrayLiteralElement = Symptom

    init(arrayLiteral elements: Symptom...) {
        symptoms = Set(elements)
    }
}

extension Symptoms: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(contentsOf: symptoms)
    }
}

extension Symptoms: Decodable {
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()

        var symptoms: Set<Symptom> = []
        while !container.isAtEnd {
            symptoms.insert(try container.decode(Symptom.self))
        }

        self.symptoms = symptoms
    }
}
