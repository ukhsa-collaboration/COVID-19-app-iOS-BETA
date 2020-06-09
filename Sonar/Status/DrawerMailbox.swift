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
    static let DrawerMessagePosted = NSNotification.Name("DrawerMessagePosted")

    case unexposed
    case symptomsButNotSymptomatic
    case positiveTestResult
    case negativeTestResult
    case unclearTestResult
    case checkin
}

class DrawerMailbox: DrawerMailboxing {

    let persistence: Persisting
    let notificationCenter: NotificationCenter

    private var messages: [DrawerMessage] {
        get { persistence.drawerMessages }
        set { persistence.drawerMessages = newValue }
    }

    init(persistence: Persisting, notificationCenter: NotificationCenter) {
        self.persistence = persistence
        self.notificationCenter = notificationCenter
    }

    func receive() -> DrawerMessage? {
        guard !messages.isEmpty else { return nil }

        return messages.removeFirst()
    }

    func post(_ message: DrawerMessage) {
        if message == .checkin {
            messages.removeAll { $0 == .checkin }
        }

        messages.append(message)
        notificationCenter.post(name: DrawerMessage.DrawerMessagePosted, object: message)
    }

}

extension DrawerMessage: Codable {
    enum Error: Swift.Error {
        case decodingError(String)
    }

    enum CodingKeys: String, CodingKey {
        case type
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let type = try values.decode(String.self, forKey: .type)
        switch type {
        case "unexposed":
            self = .unexposed
        case "symptomsButNotSymptomatic":
            self = .symptomsButNotSymptomatic
        case "positiveTestResult":
            self = .positiveTestResult
        case "negativeTestResult":
            self = .negativeTestResult
        case "unclearTestResult":
            self = .unclearTestResult
        case "checkin":
            self = .checkin
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
        case .positiveTestResult:
            try container.encode("positiveTestResult", forKey: .type)
        case .negativeTestResult:
            try container.encode("negativeTestResult", forKey: .type)
        case .unclearTestResult:
            try container.encode("unclearTestResult", forKey: .type)
        case .checkin:
            try container.encode("checkin", forKey: .type)
        }
    }

}
