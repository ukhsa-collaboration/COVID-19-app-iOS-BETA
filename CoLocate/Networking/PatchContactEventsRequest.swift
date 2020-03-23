//
//  PatchContactEventsRequest.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct PatchContactEventsRequest: Request {

    struct JSONWrapper: Codable {
        let contactEvents: [ContactEvent]
    }

    typealias ResponseType = Void
    
    let method: HTTPMethod
    
    let path: String
    
    let headers: [String : String] = [
        "Accept": "application/json",
        "Content-Type": "application/json"
    ]
    
    init(deviceId: UUID, contactEvents: [ContactEvent]) {
        path = "/api/residents/\(deviceId.uuidString)"
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let contactEvents = JSONWrapper(contactEvents: contactEvents)
        method = .patch(data: try! encoder.encode(contactEvents))
    }
    
    func parse(_ data: Data) throws -> Void {
    }
        
}
