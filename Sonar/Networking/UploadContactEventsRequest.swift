//
//  PatchContactEventsRequest.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

class UploadContactEventsRequest: SecureRequest, Request {

    struct JSONWrapper: Codable {
        let symptomsTimestamp: Date
        let contactEvents: [ContactEvent]
    }

    typealias ResponseType = Void
    
    let method: HTTPMethod
    
    let urlable: Urlable

    init(registration: Registration, symptomsTimestamp: Date, contactEvents: [ContactEvent]) {
        let key = registration.secretKey
        let sonarId = registration.id
        urlable = .path("/api/residents/\(sonarId.uuidString)")

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
