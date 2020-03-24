//
//  PatchContactEventsRequest.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CryptoKit

class PatchContactEventsRequest: SecureRequest, Request {

    struct JSONWrapper: Codable {
        let contactEvents: [ContactEvent]
    }

    typealias ResponseType = Void
    
    let method: HTTPMethod
    
    let path: String
    
    init(key: SymmetricKey, deviceId: UUID, contactEvents: [ContactEvent]) {
        path = "/api/residents/\(deviceId.uuidString)"

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let contactEvents = JSONWrapper(contactEvents: contactEvents)
        let contactEventsData = try! encoder.encode(contactEvents)
        method = .patch(data: contactEventsData)

        super.init(key, contactEventsData, [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ])
    }
    
    func parse(_ data: Data) throws -> Void {
    }
        
}
