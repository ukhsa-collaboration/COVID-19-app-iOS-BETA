//
//  StatusState.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

enum StatusState: Equatable {
    struct Ok: Codable, Equatable {}

    struct Symptomatic: Codable, Equatable {
        let symptoms: Set<Symptom>
        let startDate: Date

        var expiryDate: Date {
            let startOfStartDate = Calendar.current.startOfDay(for: startDate)
            let expiryDate = Calendar.current.nextDate(
                after: Calendar.current.date(byAdding: .day, value: 7, to: startOfStartDate)!,
                matching: DateComponents(hour: 7),
                matchingPolicy: .nextTime
            )!
            return expiryDate
        }
    }

    struct Checkin: Codable, Equatable {
        let symptoms: Set<Symptom>
        let checkinDate: Date
    }

    struct Exposed: Codable, Equatable {
        let exposureDate: Date
    }

    case ok(Ok)                   // default state, previously "blue"
    case symptomatic(Symptomatic) // previously "red" state
    case checkin(Checkin)
    case exposed(Exposed)         // previously "amber" state

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
        case symptomatic
        case checkin
        case exposed
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
            try container.encode(symptomatic, forKey: .symptomatic)
        case .checkin(let checkin):
            try container.encode("checkin", forKey: .type)
            try container.encode(checkin, forKey: .checkin)
        case .exposed(let exposed):
            try container.encode("exposed", forKey: .type)
            try container.encode(exposed, forKey: .exposed)
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
            self = .ok(StatusState.Ok())
        case "symptomatic":
            let symptomatic = try values.decode(Symptomatic.self, forKey: .symptomatic)
            self = .symptomatic(symptomatic)
        case "checkin":
            let checkin = try values.decode(Checkin.self, forKey: .checkin)
            self = .checkin(checkin)
        case "exposed":
            let exposed = try values.decode(Exposed.self, forKey: .exposed)
            self = .exposed(exposed)
        default:
            throw Error.decodingError("Unrecognized type: \(type)")
        }
    }
}
