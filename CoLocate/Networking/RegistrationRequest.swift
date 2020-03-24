//
//  RegistrationRequest.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct RegistrationResponse: Codable {
    let id: UUID
    let secretKey: String
    
    init(id: UUID, secretKey: String) {
        self.id = id
        self.secretKey = secretKey
    }
}

class RegistrationRequest: Request {
    typealias ResponseType = RegistrationResponse
    
    let method = HTTPMethod.post(data: "{}".data(using: .utf8)!)
    let path = "api/residents"
    let headers = ["Content-Type": "application/json"]
    
    func parse(_ data: Data) throws -> RegistrationResponse {
        let decoder = JSONDecoder()
        let response = try decoder.decode(RegistrationResponse.self, from: data)
        return response
    }
}
