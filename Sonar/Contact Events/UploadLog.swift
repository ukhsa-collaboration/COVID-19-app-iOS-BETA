//
//  UploadLog.swift
//  Sonar
//
//  Created by NHSX on 4/24/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct UploadLog: Codable, Equatable {
    let date: Date
    let event: Event

    init(date: Date = Date(), event: Event) {
        self.date = date
        self.event = event
    }

    enum Event: Equatable {
        case requested(startDate: Date)
        case started(lastContactEventDate: Date)
        case completed(error: String?)

        var key: String {
            switch self {
            case .requested: return "requested"
            case .started: return "started"
            case .completed: return "completed"
            }
        }
    }
}

extension UploadLog.Event: Codable {
    private enum CodingKeys: CodingKey {
        case key
        case startDate
        case lastContactEventDate
        case error
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(String.self, forKey: .key) {
        case "requested":
            let startDate = try container.decode(Date.self, forKey: .startDate)
            self = .requested(startDate: startDate)
        case "started":
            let lastContactEventDate = try container.decode(Date.self, forKey: .lastContactEventDate)
            self = .started(lastContactEventDate: lastContactEventDate)
        case "completed":
            let error = try container.decode(String?.self, forKey: .error)
            self = .completed(error: error)
        default:
            throw Error.invalidCase
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        switch self {
        case .requested(let startDate):
            try container.encode(startDate, forKey: .startDate)
        case .started(let lastContactEventDate):
            try container.encode(lastContactEventDate, forKey: .lastContactEventDate)
        case .completed(let error):
            try container.encode(error, forKey: .error)
        }
    }

    enum Error: Swift.Error {
        case invalidCase
    }
}
