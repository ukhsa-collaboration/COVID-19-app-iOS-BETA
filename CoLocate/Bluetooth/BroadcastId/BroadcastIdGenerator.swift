//
//  BroadcastIdGenerator.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Security

import Logging

class BroadcastIdGenerator {

    public static var useNewBroadcastId = false

    let serverPublicKey: SecKey
    let sonarId: UUID

    let oneDay: TimeInterval = 86400

    struct CachedResult {
        let date: Date
        let broadcastId: Data
    }

    var cached: CachedResult?

    init(key: SecKey, sonarId: UUID) {
        self.serverPublicKey = key
        self.sonarId = sonarId
    }

    func broadcastId(for startDate: Date = Date(), until maybeDate: Date? = nil) -> Data {
        if BroadcastIdGenerator.useNewBroadcastId == false {
            return bytesFromSonarId()
        }

        if cached?.date == startDate {
            return cached!.broadcastId
        }

        let endDate: Date = maybeDate ?? startDate.addingTimeInterval(oneDay)

        let firstPart = bytesFrom(startDate)
        let secondPart = bytesFrom(endDate)
        let thirdPart = bytesFromSonarId()

        assert(firstPart.count == 4)
        assert(secondPart.count == 4)
        assert(thirdPart.count == 16)

        var plainTextData = Data(capacity: 24)

        plainTextData.append(firstPart)
        plainTextData.append(secondPart)
        plainTextData.append(thirdPart)

        var error: Unmanaged<CFError>?
        let cipherText = SecKeyCreateEncryptedData(serverPublicKey,
                                                   SecKeyAlgorithm.eciesEncryptionStandardX963SHA256AESGCM,
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

        cached = CachedResult(date: startDate, broadcastId: result)

        return result
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
}

//MARK: - Logging

fileprivate let logger = Logger(label: "BTLE")
