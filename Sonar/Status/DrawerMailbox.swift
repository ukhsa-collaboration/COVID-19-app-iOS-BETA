//
//  DrawerMailbox.swift
//  Sonar
//
//  Created by NHSX on 5/27/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

protocol DrawerMailboxing {
    func receive() -> DrawerMessage?
    func post(_ message: DrawerMessage)
}

enum DrawerMessage: Equatable {
    case unexposed
    case symptomsButNotSymptomatic
    case testResult(TestResult.ResultType)
}

class DrawerMailbox: DrawerMailboxing {

    let persistence: Persisting

    private var messages: [DrawerMessage] {
        get { persistence.drawerMessages }
        set { persistence.drawerMessages = newValue }
    }

    init(persistence: Persisting) {
        self.persistence = persistence
    }

    func receive() -> DrawerMessage? {
        guard !messages.isEmpty else { return nil }

        return messages.removeFirst()
    }

    func post(_ message: DrawerMessage) {
        messages.append(message)
    }

}

extension DrawerMessage: Codable {
    enum Error: Swift.Error {
        case decodingError(String)
    }

    enum CodingKeys: String, CodingKey {
        case type
        case testResult
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let type = try values.decode(String.self, forKey: .type)
        switch type {
        case "unexposed":
            self = .unexposed
        case "symptomsButNotSymptomatic":
            self = .symptomsButNotSymptomatic
        case "testResult":
            let testResult = try values.decode(TestResult.ResultType.self, forKey: .testResult)
            self = .testResult(testResult)
        default:
            throw Error.decodingError("Unrecognized type: \(type)")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .unexposed:
            try container.encode("unexposed", forKey: .type)
        case .symptomsButNotSymptomatic:
            try container.encode("symptomsButNotSymptomatic", forKey: .type)
        case .testResult(let testResult):
            try container.encode("testResult", forKey: .type)
            try container.encode(testResult, forKey: .testResult)
        }
    }

}
