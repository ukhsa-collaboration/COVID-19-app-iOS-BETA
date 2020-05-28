//
//  StatusState.swift
//  Sonar
//
//  Created by NHSX on 5/11/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

protocol Expirable {
    /// Duration is in days
    var duration: Int { get }
    var startDate: Date { get }
    var expiryDate: Date { get }
}

extension Expirable {
    var expiryDate: Date {
        let startOfStartDate = Calendar.current.startOfDay(for: startDate)
        let expiryDate = Calendar.current.nextDate(
            after: Calendar.current.date(byAdding: .day, value: duration, to: startOfStartDate)!,
            matching: DateComponents(hour: 7),
            matchingPolicy: .nextTime
        )!
        return expiryDate
    }
}

indirect enum StatusState: Equatable {
    struct Ok: Codable, Equatable {}

    struct Symptomatic: Codable, Equatable {
        static func firstCheckin(from startDate: Date) -> Date {
            return nextCheckin(from: startDate, afterDays: 7)
        }

        static func nextCheckin(from startDate: Date, afterDays days: Int = 1) -> Date {
            let startOfStartDate = Calendar.current.startOfDay(for: startDate)
            let expiryDate = Calendar.current.nextDate(
                after: Calendar.current.date(byAdding: .day, value: days, to: startOfStartDate)!,
                matching: DateComponents(hour: 7),
                matchingPolicy: .nextTime
            )!
            return expiryDate
        }

        let symptoms: Symptoms?
        let startDate: Date
        let checkinDate: Date

    }

    struct Exposed: Codable, Equatable, Expirable {
        let startDate: Date
        let duration = 14
    }
    
    struct PositiveTestResult: Codable, Equatable, Expirable {
        // Optional since we might not have asked the
        // user for their symptoms before they have a
        // positive test result.
        let symptoms: Symptoms?

        let startDate: Date
        let duration = 7
    }

    case ok(Ok)                   // default state, previously "blue"
    case symptomatic(Symptomatic) // previously "red" state
    case exposed(Exposed)         // previously "amber" state
    case positiveTestResult(PositiveTestResult)

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
        case nextState
        
        case symptomatic
        case checkin
        case exposed
        case positiveTestResult
        case unclearTestResult
        case negativeTestResult
    }
}

extension StatusState {
    var symptoms: Symptoms? {
        switch self {
        case .ok, .exposed:
            return nil
        case .symptomatic(let state):
            return state.symptoms
        case .positiveTestResult(let state):
            return state.symptoms
        }
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
        case .exposed(let exposed):
            try container.encode("exposed", forKey: .type)
            try container.encode(exposed, forKey: .exposed)
        case .positiveTestResult(let positiveTestResult):
            try container.encode("positiveTestResult", forKey: .type)
            try container.encode(positiveTestResult, forKey: .positiveTestResult)
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
        case "exposed":
            let exposed = try values.decode(Exposed.self, forKey: .exposed)
            self = .exposed(exposed)
        case "positiveTestResult":
            let positiveTestResult = try values.decode(PositiveTestResult.self, forKey: .positiveTestResult)
            self = .positiveTestResult(positiveTestResult)
        default:
            throw Error.decodingError("Unrecognized type: \(type)")
        }
    }
}
