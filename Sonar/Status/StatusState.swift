//
//  StatusState.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

enum StatusState: Equatable {
    case ok // default state, previously "blue"
    case symptomatic(symptoms: Set<Symptom>, expires: Date) // previously "red" state
    case checkin(symptoms: Set<Symptom>, at: Date)
    case exposed(on: Date) // previously "amber" state

    enum CodingKeys: String, CodingKey {
        case type
        case symptoms
        case date
    }
}

extension StatusState: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .ok:
            try container.encode("ok", forKey: .type)
        case .symptomatic(let symptoms, let date):
            try container.encode("symptomatic", forKey: .type)
            try container.encode(symptoms, forKey: .symptoms)
            try container.encode(date, forKey: .date)
        case .checkin(let symptoms, let date):
            try container.encode("checkin", forKey: .type)
            try container.encode(symptoms, forKey: .symptoms)
            try container.encode(date, forKey: .date)
        case .exposed(let date):
            try container.encode("exposed", forKey: .type)
            try container.encode(date, forKey: .date)
        }
    }
}

extension StatusState: Decodable {
    enum Error: Swift.Error {
        case decodingError(String)
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let type = try values.decode(String.self, forKey: .type)
        switch type {
        case "ok":
            self = .ok
        case "symptomatic":
            let symptoms = try values.decode(Set<Symptom>.self, forKey: .symptoms)
            let date = try values.decode(Date.self, forKey: .date)
            self = .symptomatic(symptoms: symptoms, expires: date)
        case "checkin":
            let symptoms = try values.decode(Set<Symptom>.self, forKey: .symptoms)
            let date = try values.decode(Date.self, forKey: .date)
            self = .checkin(symptoms: symptoms, at: date)
        case "exposed":
            let date = try values.decode(Date.self, forKey: .date)
            self = .exposed(on: date)
        default:
            throw Error.decodingError("Unrecognized type: \(type)")
        }
    }
}
