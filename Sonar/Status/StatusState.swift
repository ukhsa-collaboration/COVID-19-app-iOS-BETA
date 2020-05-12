//
//  StatusState.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

enum StatusState: Equatable {
    struct Symptomatic: Equatable {
        let symptoms: Set<Symptom>
        let expiryDate: Date
    }

    struct Checkin: Equatable {
        let symptoms: Set<Symptom>
        let checkinDate: Date
    }

    struct Exposed: Equatable {
        let exposureDate: Date
    }

    case ok // default state, previously "blue"
    case symptomatic(Symptomatic) // previously "red" state
    case checkin(Checkin)
    case exposed(Exposed) // previously "amber" state

    var isSymptomatic: Bool {
        if case .symptomatic = self {
            return true
        } else {
            return false
        }
    }

    var isExposed: Bool {
        if case .exposed = self {
            return true
        } else {
            return false
        }
    }

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
        case .symptomatic(let symptomatic):
            try container.encode("symptomatic", forKey: .type)
            try container.encode(symptomatic.symptoms, forKey: .symptoms)
            try container.encode(symptomatic.expiryDate, forKey: .date)
        case .checkin(let checkin):
            try container.encode("checkin", forKey: .type)
            try container.encode(checkin.symptoms, forKey: .symptoms)
            try container.encode(checkin.checkinDate, forKey: .date)
        case .exposed(let exposed):
            try container.encode("exposed", forKey: .type)
            try container.encode(exposed.exposureDate, forKey: .date)
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
            self = .symptomatic(Symptomatic(symptoms: symptoms, expiryDate: date))
        case "checkin":
            let symptoms = try values.decode(Set<Symptom>.self, forKey: .symptoms)
            let date = try values.decode(Date.self, forKey: .date)
            self = .checkin(Checkin(symptoms: symptoms, checkinDate: date))
        case "exposed":
            let date = try values.decode(Date.self, forKey: .date)
            self = .exposed(Exposed(exposureDate: date))
        default:
            throw Error.decodingError("Unrecognized type: \(type)")
        }
    }
}
