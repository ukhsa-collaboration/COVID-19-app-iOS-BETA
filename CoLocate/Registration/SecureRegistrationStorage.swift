//
//  SecureRegistrationStorage.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Security
import Logging

struct Registration: Codable, Equatable {
    let id: UUID
    let secretKey: Data

    init(id: UUID, secretKey: Data) {
        self.id = id
        self.secretKey = secretKey
    }
}

class SecureRegistrationStorage {

    enum Error: Swift.Error {
        case invalidSecretKey
        case keychain(OSStatus)
    }

    static let secService = "registration"

    func get() throws -> Registration? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: SecureRegistrationStorage.secService,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess: break
        case errSecItemNotFound: return nil
        default:
            logger.critical("Unhandled status from SecItemCopy: \(status)")
            throw Error.keychain(status)
        }

        guard let item = result as? [String : Any],
            let data = item[kSecValueData as String] as? Data,
            let idString = item[kSecAttrAccount as String] as? String,
            let id = UUID(uuidString: idString) else {
                logger.error("Could not read registration data from keychain")
                return nil
        }

        return Registration(id: id, secretKey: data)
    }

    func set(registration: Registration) throws {
        try clear()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: SecureRegistrationStorage.secService,
            kSecAttrAccount as String: registration.id.uuidString,
            kSecValueData as String: registration.secretKey,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess || status == errSecDuplicateItem else {
            logger.error("Failed to add registration to keychain: \(status)")
            throw Error.keychain(status)
        }
    }

    func clear() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: SecureRegistrationStorage.secService,
        ]
        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            logger.error("Failed to add clear registration from keychain : \(status)")
            throw Error.keychain(status)
        }
    }

}

fileprivate let logger = Logger(label: "RegistrationStorage")
