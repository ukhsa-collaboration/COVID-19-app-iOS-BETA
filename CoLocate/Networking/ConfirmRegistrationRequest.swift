//
//  ConfirmRegistrationRequest.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CryptoKit

class ConfirmRegistrationRequest: Request {
    
    typealias ResponseType = ConfirmRegistrationResponse
    
    struct ConfirmRegistrationResponse: Decodable {
        
        enum CodingKeys: String, CodingKey {
            case id, secretKey
        }
        
        let id: UUID
        let secretKey: SymmetricKey

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)

            id = try values.decode(UUID.self, forKey: .id)

            let base64SymmetricKey = try values.decode(String.self, forKey: .secretKey)
            if let data = Data(base64Encoded: base64SymmetricKey) {
                secretKey = SymmetricKey(data: data)
            } else {
                throw DecodingError.dataCorruptedError(forKey: .secretKey, in: values, debugDescription: "Invalid base64 value")
            }
        }
        
    }
    
    let method: HTTPMethod
    
    let path: String
    
    let headers: [String : String]
    
    init(activationCode: UUID, pushToken: String) {
        path = "/api/devices"
        headers = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
        struct Body: Codable {
            let activationCode: UUID
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
