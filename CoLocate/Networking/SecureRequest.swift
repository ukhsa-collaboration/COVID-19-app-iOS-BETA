//
//  SecureRequest.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CryptoKit

class SecureRequest {
    
    static let timestampHeader = "X-Sonar-Message-Timestamp"
    static let signatureHeader = "X-Sonar-Message-Signature"
    
    var headers: [String : String]
    
    init(_ key: SymmetricKey, _ data: Data, _ headers: [String: String], _ timestamp: Date = Date()) {
        let timestampString = ISO8601DateFormatter().string(from: timestamp)
        
        var hmac = HMAC<SHA256>(key: key);
        hmac.update(data: timestampString.data(using: .utf8)!)
        hmac.update(data: data)
        let authenticationCode = hmac.finalize()

        self.headers = headers
        self.headers[SecureRequest.timestampHeader] = timestampString
        self.headers[SecureRequest.signatureHeader] = authenticationCode.withUnsafeBytes() { ptr -> String in
            let data = Data(bytes: ptr.baseAddress!, count: ptr.count)
            return data.base64EncodedString(options: [])
        }
        
    }
    
}
