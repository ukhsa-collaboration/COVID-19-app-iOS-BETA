//
//  BroadcastIdEncrypter.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Security

import Logging

class BroadcastIdEncrypter {

    let serverPublicKey: SecKey
    let sonarId: UUID

    let oneDay: TimeInterval = 86400

    static var broadcastIdLength: Int {
        return 106
    }

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
        if sameDay(startDate, cached?.date) {
            return cached!.broadcastId
        }

        let endDate: Date = maybeDate ?? startDate.addingTimeInterval(oneDay)

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
        assert(withoutFirstByte.count == BroadcastIdEncrypter.broadcastIdLength, "unexpected number of bytes: \(withoutFirstByte.count)")

        cached = CachedResult(date: startDate, broadcastId: withoutFirstByte)

        return withoutFirstByte
    }

    // MARK: - Private

    private func sameDay(_ first: Date, _ second: Date?) -> Bool {
        guard let second = second else { return false }

        let calendar = Calendar.current

        let date1 = calendar.startOfDay(for: first)
        let date2 = calendar.startOfDay(for: second)

        let components = calendar.dateComponents([.day], from: date1, to: date2)
        return components.day == 0
    }

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
