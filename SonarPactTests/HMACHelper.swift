//
//  HMACHelper.swift
//  SonarPactTests
//
//  Created by NHSX on 22/5/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CommonCrypto

@testable import Sonar

class HMACHelper {
    // Pact uses JSONSerialization to send the request, which adds newlines and spaces.
    // This means the signature is invalid since JsonEncoder does not add newlines and spaces.
    // So we'll need to regenerate the signature here.
    
    static func createSignatureForBodyWithNewlinesAndSpaces(_ key: HMACKey, _ body: Any, _ timestamp: String) -> String {
        let data = try! JSONSerialization.data(
            withJSONObject: body,
            options: []
        )
        
        var hmacContext = CCHmacContext()
        
        key.data.withUnsafeBytes { keyPtr -> Void in
            CCHmacInit(&hmacContext, CCHmacAlgorithm(kCCHmacAlgSHA256), keyPtr.baseAddress, key.data.count)
        }
        
        let tsData = timestamp.data(using: .utf8)!
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
        
        return authenticationCode.base64EncodedString(options: [])
    }
}
