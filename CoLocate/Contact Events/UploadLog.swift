//
//  UploadLog.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct UploadLog: Codable, Equatable {
    let date = Date()
    let event: Event

    enum Event: Equatable {
        case requested
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
    enum CodingKeys: CodingKey {
        case key
        case lastContactEventDate
        case error
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(String.self, forKey: .key) {
        case "requested":
            self = .requested
        case "started":
            let date = try container.decode(Date.self, forKey: .lastContactEventDate)
            self = .started(lastContactEventDate: date)
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
        case .requested:
            break
        case .started(let date):
            try container.encode(date, forKey: .lastContactEventDate)
        case .completed(let error):
            try container.encode(error, forKey: .error)
        }
    }

    enum Error: Swift.Error {
        case invalidCase
    }
}
