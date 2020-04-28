//
//  RegistrationRequest.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct RegistrationRequest: Request {
    
    private struct RegistrationRequestJSON: Codable {
        let pushToken: String
    }
    
    typealias ResponseType = Void
    
    let method: HTTPMethod
    let path = "/api/devices/registrations"
    let headers = ["Content-Type": "application/json"]
    
    init(pushToken: String) {
        let requestJSON = RegistrationRequestJSON(pushToken: pushToken)
        method = HTTPMethod.post(data: try! JSONEncoder().encode(requestJSON))
    }
    
    func parse(_ data: Data) throws -> Void {
    }

}
