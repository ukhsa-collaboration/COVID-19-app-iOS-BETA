//
//  BroadcastPayload.swift
//  SonarTests
//
//  Created by NHSX on 30.04.20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CommonCrypto
import Logging

struct BroadcastPayload {
    
    static let length: Int = 129
    static let ukISO3166CountryCode: Int16 = 826
    
    let txPower: Int8 = 0
    
    let cryptogram: Data
    let hmacKey: HMACKey
        
    func data(txDate: Date = Date()) -> Data {
        logger.info("generating broadcast payload with txDate = \(txDate)")
        var payload = Data()
        
        payload.append(BroadcastPayload.ukISO3166CountryCode.networkByteOrderData)
        payload.append(cryptogram)
        payload.append(txPower.networkByteOrderData)
        payload.append(Int32(txDate.timeIntervalSince1970).networkByteOrderData)
        
        let signature = hmacSignature(hmacKey: hmacKey, data: payload)
        payload.append(signature)
        
        assert(payload.count == BroadcastPayload.length, "Broadcast payload should be \(BroadcastPayload.length), not \(payload.count)")
        return payload
    }
    
    private func hmacSignature(hmacKey: HMACKey, data: Data) -> Data {
        var context = CCHmacContext()
        
        hmacKey.data.withUnsafeBytes { ptr in
            CCHmacInit(&context, CCHmacAlgorithm(kCCHmacAlgSHA256), ptr.baseAddress, hmacKey.data.count)
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

struct IncomingBroadcastPayload: Equatable, Codable {
    
    let countryCode: Int16
    let cryptogram: Data
    let txPower: Int8
    let transmissionTime: Int32
    let hmac: Data
    
    init(data: Data) {
        self.countryCode = Int16(bigEndian: data.subdata(in: 0..<2).to(type: Int16.self)!)
        self.cryptogram = data.subdata(in: 2..<108)
        self.txPower = data.subdata(in: 108..<109).to(type: Int8.self)!
        self.transmissionTime = Int32(bigEndian: data.subdata(in: 109..<113).to(type: Int32.self)!)
        self.hmac = data.subdata(in: 113..<129)
    }

}

fileprivate let logger = Logger(label: "BTLE")
