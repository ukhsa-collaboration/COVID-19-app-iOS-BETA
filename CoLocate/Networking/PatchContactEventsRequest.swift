//
//  PatchContactEventsRequest.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct PatchContactEventsRequest: Request {

    typealias ResponseType = Void
    
    var method: HTTPMethod {
        return .patch(data: data)
    }
    
    let path: String
    
    let data: Data
    
    var headers: [String : String]? = [
        "Accept": "application/json",
        "Content-Type": "application/json"
    ]
    
    init(deviceId: UUID, contactEvents: [ContactEvent]) {
        path = "/api/residents/\(deviceId.uuidString)"
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        data = try! encoder.encode(contactEvents)
    }
    
    func parse(_ data: Data) throws -> Void {
    }
        
}
