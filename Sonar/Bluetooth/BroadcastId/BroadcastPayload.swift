//
//  BroadcastPayload.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CommonCrypto
import Logging

struct BroadcastPayload {
    
    static let length: Int = 129
    static let ukISO3166CountryCode: UInt16 = 826
    
    let txPower: Int8 = 0
    
    let cryptogram: Data
    let secKey: SecKey
    
    func data(txDate: Date = Date()) -> Data {
        var payload = Data()
        
        payload.append(BroadcastPayload.ukISO3166CountryCode.data)
        payload.append(cryptogram)
        payload.append(txPower.data)
        payload.append(Int32(txDate.timeIntervalSince1970).data)
        
        let signature = hmacSignature(secKey: secKey, data: payload)
        payload.append(signature)
        
        return payload
    }
    
    private func hmacSignature(secKey: SecKey, data: Data) -> Data {
        guard let key = secKey.externalRepresentation else {
            logger.info("couldn't extract key data from secKey")
            return Data()
        }
        
        var context = CCHmacContext()
        
        key.withUnsafeBytes { ptr in
            CCHmacInit(&context, CCHmacAlgorithm(kCCHmacAlgSHA256), ptr.baseAddress, key.count)
        }
        
        data.withUnsafeBytes { ptr in
            CCHmacUpdate(&context, ptr.baseAddress, data.count)
        }
        
        var hmac = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        hmac.withUnsafeMutableBytes { ptr in
            CCHmacFinal(&context, ptr.baseAddress)
        }
        return hmac.subdata(in: 0..<16)
    }

}

fileprivate let logger = Logger(label: "BTLE")
