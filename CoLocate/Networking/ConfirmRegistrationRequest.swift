//
//  ConfirmRegistrationRequest.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

class ConfirmRegistrationRequest: Request {
    
    typealias ResponseType = ConfirmRegistrationResponse
        
    let method: HTTPMethod
    
    let path: String
    
    let headers: [String : String]
    
    init(activationCode: String, pushToken: String) {
        path = "/api/devices"
        headers = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
        struct Body: Codable {
            let activationCode: String
            let pushToken: String
        }
        let data = try! JSONEncoder().encode(Body(activationCode: activationCode, pushToken: pushToken))
        method = HTTPMethod.post(data: data)
    }
    
    func parse(_ data: Data) throws -> ConfirmRegistrationResponse {
        let decoder = JSONDecoder()
        return try decoder.decode(ConfirmRegistrationResponse.self, from: data)
    }
}

struct ConfirmRegistrationResponse: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case id, secretKey
    }
    
    let id: UUID
    let secretKey: Data

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let id = try values.decode(UUID.self, forKey: .id)

        let base64SymmetricKey = try values.decode(String.self, forKey: .secretKey)
        guard let secretKey = Data(base64Encoded: base64SymmetricKey) else {
            throw DecodingError.dataCorruptedError(forKey: .secretKey, in: values, debugDescription: "Invalid base64 value")
        }
        
        self.init(id: id, secretKey: secretKey)
    }
    
    init(id: UUID, secretKey: Data) {
        self.id = id
        self.secretKey = secretKey
    }

}
