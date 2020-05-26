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

    struct Symptomatic: Codable, Equatable, Expirable {
        let symptoms: Symptoms
        let startDate: Date
        let duration = 7
    }

    struct Checkin: Codable, Equatable {
        // We can get into the checkin state without knowing
        // initial symptoms from getting a positive test result.
        let symptoms: Symptoms?

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

    struct Unexposed: Codable, Equatable {}
    
    struct UnclearTestResult: Codable, Equatable, Expirable {
        let symptoms: Symptoms?
        let duration: Int = 7
        let startDate: Date
    }
    
    struct NegativeTestResult: Codable, Equatable {
        let symptoms: Symptoms?
    }

    case ok(Ok)                   // default state, previously "blue"
    case symptomatic(Symptomatic) // previously "red" state
    case checkin(Checkin)
    case exposed(Exposed)         // previously "amber" state
    case unexposed(Unexposed)
    case positiveTestResult(PositiveTestResult)
    case unclearTestResult(UnclearTestResult)
    case negativeTestResult(NegativeTestResult, nextState: StatusState)
    
    /// Returns the ultimate state after an interstitial state has completed
    func resolved() -> StatusState {
        switch self {
        case .negativeTestResult(_, let nextState):
            return nextState
        case .unclearTestResult(let unclear):
            guard let symptoms = unclear.symptoms else {
                assertionFailure("What do we do here?")
                return self
            }
            return .symptomatic(Symptomatic(symptoms: symptoms, startDate: unclear.startDate))
        default:
            return self
        }
    }

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
        case .ok, .exposed, .unexposed:
            return nil
        case .symptomatic(let state):
            return state.symptoms
        case .checkin(let state):
            return state.symptoms
        case .positiveTestResult(let state):
            return state.symptoms
        case .unclearTestResult(let state):
            return state.symptoms
        case .negativeTestResult(let state, _):
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
        case .checkin(let checkin):
            try container.encode("checkin", forKey: .type)
            try container.encode(checkin, forKey: .checkin)
        case .exposed(let exposed):
            try container.encode("exposed", forKey: .type)
            try container.encode(exposed, forKey: .exposed)
        case .unexposed:
            try container.encode("unexposed", forKey: .type)
        case .positiveTestResult(let positiveTestResult):
            try container.encode("positiveTestResult", forKey: .type)
            try container.encode(positiveTestResult, forKey: .positiveTestResult)
        case .unclearTestResult(let unclearTestResult):
            try container.encode("unclearTestResult", forKey: .type)
            try container.encode(unclearTestResult, forKey: .unclearTestResult)
        case .negativeTestResult(let negativeTestResult, let nextState):
            try container.encode("negativeTestResult", forKey: .type)
            try container.encode(negativeTestResult, forKey: .negativeTestResult)
            try container.encode(nextState, forKey: .nextState)
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
        case "unexposed":
            self = .unexposed(StatusState.Unexposed())
        case "positiveTestResult":
            let positiveTestResult = try values.decode(PositiveTestResult.self, forKey: .positiveTestResult)
            self = .positiveTestResult(positiveTestResult)
        case "unclearTestResult":
            let unclearTestResult = try values.decode(UnclearTestResult.self, forKey: .unclearTestResult)
            self = .unclearTestResult(unclearTestResult)
        case "negativeTestResult":
            let negativeTestResult = try values.decode(NegativeTestResult.self, forKey: .negativeTestResult)
            let nextState = try values.decode(StatusState.self, forKey: .nextState)
            self = .negativeTestResult(negativeTestResult, nextState: nextState)
        default:
            throw Error.decodingError("Unrecognized type: \(type)")
        }
    }
}
