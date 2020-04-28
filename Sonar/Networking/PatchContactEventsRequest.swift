//
//  PatchContactEventsRequest.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

class PatchContactEventsRequest: SecureRequest, Request {

    struct JSONWrapper: Codable {
        let symptomsTimestamp: Date
        let contactEvents: [ContactEvent]
    }

    typealias ResponseType = Void
    
    let method: HTTPMethod
    
    let path: String
    
    init(key: Data, sonarId: UUID, symptomsTimestamp: Date, contactEvents: [ContactEvent]) {
        path = "/api/residents/\(sonarId.uuidString)"

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let requestBody = JSONWrapper(symptomsTimestamp: symptomsTimestamp, contactEvents: contactEvents)
        let bodyAsData = try! encoder.encode(requestBody)
        method = .patch(data: bodyAsData)

        super.init(key, bodyAsData, [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ])
    }
    
    func parse(_ data: Data) throws -> Void {
    }
        
}
