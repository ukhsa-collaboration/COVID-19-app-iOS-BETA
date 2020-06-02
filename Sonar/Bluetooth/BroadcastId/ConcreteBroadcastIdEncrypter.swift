//
//  BroadcastIdEncrypter.swift
//  Sonar
//
//  Created by NHSX on 08/04/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Security
import CommonCrypto
import Logging

protocol BroadcastIdEncrypter {
    func broadcastId(secKey: SecKey, sonarId: UUID, from startDate: Date, until endDate: Date) -> Data
}

class ConcreteBroadcastIdEncrypter: BroadcastIdEncrypter {

    static let broadcastIdLength: Int = 106
    static let txPower: Int8 = 0
    
    func broadcastId(secKey: SecKey, sonarId: UUID, from startDate: Date, until endDate: Date) -> Data {
        var plaintext = Data(capacity: 26)
        plaintext.append(UInt32(startDate.timeIntervalSince1970).networkByteOrderData)
        plaintext.append(UInt32(endDate.timeIntervalSince1970).networkByteOrderData)
        plaintext.append(sonarId.data)
        plaintext.append(UInt16(BroadcastPayload.ukISO3166CountryCode).networkByteOrderData)

        var error: Unmanaged<CFError>?
        let cipherText = SecKeyCreateEncryptedData(secKey,
                                                   SecKeyAlgorithm.eciesEncryptionStandardVariableIVX963SHA256AESGCM,
                                                   plaintext as CFData,
                                                   &error) as Data?

        guard error == nil else {
            logger.critical("error when encrypting broadcast id \(String(describing: error))")
            fatalError("\(self) error when encrypting broadcast id \(String(describing: error))")
        }
        guard let result = cipherText else {
            logger.critical("expected non nil ciphertext")
            fatalError("\(self) expected non nil ciphertext")
        }

        let withoutFirstByte = result.dropFirst()
        assert(withoutFirstByte.count == ConcreteBroadcastIdEncrypter.broadcastIdLength, "unexpected number of bytes: \(withoutFirstByte.count)")

        return withoutFirstByte
    }

}

//MARK: - Logging

fileprivate let logger = Logger(label: "BTLE")
