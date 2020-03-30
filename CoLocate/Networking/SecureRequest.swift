//
//  SecureRequest.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CommonCrypto

class SecureRequest {
    
    static let timestampHeader = "Sonar-Request-Timestamp"
    static let signatureHeader = "Sonar-Message-Signature"
    
    var headers: [String : String]
    
    /*
     TODO: Convert this to use CryptoKit once we no longer have to support iOS 12:
     init(_ key: SymmetricKey, _ data: Data, _ headers: [String: String], _ timestamp: Date = Date()) {
         let timestampString = ISO8601DateFormatter().string(from: timestamp)
         
         var hmac = HMAC<SHA256>(key: key)
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
     */
    init(_ key: Data, _ data: Data, _ headers: [String: String], _ timestamp: Date = Date()) {
        let timestampString = ISO8601DateFormatter().string(from: timestamp)
        var hmacContext = CCHmacContext()

        key.withUnsafeBytes { keyPtr -> Void in
            CCHmacInit(&hmacContext, CCHmacAlgorithm(kCCHmacAlgSHA256), keyPtr.baseAddress, key.count)
        }
        
        let tsData = timestampString.data(using: .utf8)!
        tsData.withUnsafeBytes { (tsPtr: UnsafeRawBufferPointer) -> Void in
            CCHmacUpdate(&hmacContext, tsPtr.baseAddress, tsData.count)
        }
        
        data.withUnsafeBytes { (dataPtr: UnsafeRawBufferPointer) -> Void in
            CCHmacUpdate(&hmacContext, dataPtr.baseAddress, data.count)
        }
        
        var authenticationCode = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        authenticationCode.withUnsafeMutableBytes { (digestPtr: UnsafeMutableRawBufferPointer) -> Void in
            CCHmacFinal(&hmacContext, digestPtr.baseAddress)
        }
        
        self.headers = headers
        self.headers[SecureRequest.timestampHeader] = timestampString
        self.headers[SecureRequest.signatureHeader] = authenticationCode.base64EncodedString(options: [])
    }
}
