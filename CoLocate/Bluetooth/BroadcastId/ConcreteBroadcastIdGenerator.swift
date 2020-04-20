//
//  ConcreteBroadcastIdGenerator.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Logging

protocol BroadcastIdGenerator {
    var sonarId: UUID? { get nonmutating set }

    func broadcastIdentifier() -> Data?
}

class ConcreteBroadcastIdGenerator: BroadcastIdGenerator {

    var sonarId: UUID?
    var serverPublicKey: SecKey?

    let storage: BroadcastRotationKeyStorage
    var encrypter: BroadcastIdEncrypter?

    init(storage: BroadcastRotationKeyStorage) {
        self.storage = storage
    }

    func broadcastIdentifier() -> Data? {
        guard let sonarId = sonarId else { return nil }
        let maybeKey: SecKey?
        
        do {
            maybeKey = try storage.read()
        } catch {
            logger.error("Failed to read rotation key from storage: \(error.localizedDescription)")
            return nil
        }
        
        guard let key = maybeKey else { return nil }

        return getEncrypter(key: key, sonarId: sonarId).broadcastId()
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

fileprivate let logger = Logger(label: "BTLE")
