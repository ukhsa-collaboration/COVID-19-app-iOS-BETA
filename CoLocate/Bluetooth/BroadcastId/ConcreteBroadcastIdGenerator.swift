//
//  ConcreteBroadcastIdGenerator.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

protocol BroadcastIdGenerator {
    func broadcastIdentifier() -> Data?
}

class ConcreteBroadcastIdGenerator: BroadcastIdGenerator {

    static let shared = ConcreteBroadcastIdGenerator(storage: SecureBroadcastRotationKeyStorage.shared)

    var sonarId: UUID?
    var serverPublicKey: SecKey?

    let storage: BroadcastRotationKeyStorage
    var encrypter: BroadcastIdEncrypter?

    init(storage: BroadcastRotationKeyStorage) {
        self.storage = storage
    }

    func broadcastIdentifier() -> Data? {
        guard let sonarId = sonarId else { return nil }

        return getEncrypter(key: dummyPublicKey(), sonarId: sonarId).broadcastId()
    }

    // MARK: - Private
    private func dummyPublicKey() -> SecKey {
        let base64EncodedKey = "BDSTjw7/yauS6iyMZ9p5yl6i0n3A7qxYI/3v+6RsHt8o+UrFCyULX3fKZuA6ve+lH1CAItezr+Tk2lKsMcCbHMI="

        let data = Data.init(base64Encoded: base64EncodedKey)!

        let keyDict : [NSObject:NSObject] = [
           kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
           kSecAttrKeyClass: kSecAttrKeyClassPublic,
           kSecAttrKeySizeInBits: NSNumber(value: 256),
           kSecReturnPersistentRef: true as NSObject
        ]

        return SecKeyCreateWithData(data as CFData, keyDict as CFDictionary, nil)!
    }

    private func readSigningKey() -> SecKey? {
        do {
            return try storage.read()
        } catch {
            return nil
        }
    }

    private func getEncrypter(key: SecKey, sonarId: UUID) -> BroadcastIdEncrypter {
        if self.encrypter == nil {
            self.encrypter = BroadcastIdEncrypter(key: key, sonarId: sonarId)
        }

        return self.encrypter!
    }
}
