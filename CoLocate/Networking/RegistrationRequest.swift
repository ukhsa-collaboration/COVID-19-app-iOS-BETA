//
//  RegistrationRequest.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct RegistrationRequest: Request {
    typealias ResponseType = Registration
    
    let method = HTTPMethod.post(data: "{}".data(using: .utf8)!)
    let path = "api/residents"
    let headers = ["Content-Type": "application/json"]
    
    func parse(_ data: Data) throws -> Registration {
        let decoder = JSONDecoder()
        let response = try decoder.decode(Registration.self, from: data)
        return response
    }
}
