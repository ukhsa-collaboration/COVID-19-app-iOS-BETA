//
//  BroadcastIdEncrypter.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Security
import CommonCrypto
import Logging

protocol BroadcastIdEncrypter {
    func broadcastId(from startDate: Date, until endDate: Date) -> Data
}

// TODO: this should probably now be a "thing" class like the BroadcastPayload, rather than a "doing" class as it is now
class ConcreteBroadcastIdEncrypter: BroadcastIdEncrypter {

    static let broadcastIdLength: Int = 106
    
    private let ukISO3166CountryCode: UInt16 = 826
    private let txPower: Int8 = 0
    
    let serverPublicKey: SecKey
    let sonarId: UUID

    init(key: SecKey, sonarId: UUID) {
        self.serverPublicKey = key
        self.sonarId = sonarId
    }
    
    func broadcastId(from startDate: Date, until endDate: Date) -> Data {
        let firstPart = bytesFrom(startDate)
        let secondPart = bytesFrom(endDate)
        let thirdPart = bytesFromSonarId()
        let fourthPart = bytesFromCountryCode()

        assert(firstPart.count == 4)
        assert(secondPart.count == 4)
        assert(thirdPart.count == 16)
        assert(fourthPart.count == 2)

        var plainTextData = Data(capacity: 26)

        plainTextData.append(firstPart)
        plainTextData.append(secondPart)
        plainTextData.append(thirdPart)
        plainTextData.append(fourthPart)

        var error: Unmanaged<CFError>?
        let cipherText = SecKeyCreateEncryptedData(serverPublicKey,
                                                   SecKeyAlgorithm.eciesEncryptionStandardVariableIVX963SHA256AESGCM,
                                                   plainTextData as CFData,
                                                   &error) as Data?

        guard error == nil else {
            logger.critical("error when encrypting broadcast id \(String(describing: error))")
            fatalError()
        }
        guard let result = cipherText else {
            logger.critical("expected non nil ciphertext")
            fatalError()
        }

        let withoutFirstByte = result.dropFirst()
        assert(withoutFirstByte.count == ConcreteBroadcastIdEncrypter.broadcastIdLength, "unexpected number of bytes: \(withoutFirstByte.count)")

        return withoutFirstByte
    }

    // MARK: - Private
    
    func bytesFrom(_ date: Date) -> Data {
        let interval = date.timeIntervalSince1970
        var int = Int32(interval)
        return Data(bytes: &int, count: MemoryLayout.size(ofValue: int))
    }

    func bytesFromSonarId() -> Data {
        var mutableSonarUUUID = sonarId
        return withUnsafePointer(to: &mutableSonarUUUID) {
            Data(bytes: $0, count: MemoryLayout.size(ofValue: sonarId))
        }
    }

    func bytesFromCountryCode() -> Data {
        var mutableCountryCode = 826
        return withUnsafePointer(to: &mutableCountryCode) {
            Data(bytes: $0, count: 2)
        }
    }
}

//MARK: - Logging

fileprivate let logger = Logger(label: "BTLE")
