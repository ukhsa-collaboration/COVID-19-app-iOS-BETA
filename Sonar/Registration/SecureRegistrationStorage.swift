//
//  SecureRegistrationStorage.swift
//  Sonar
//
//  Created by NHSX on 3/24/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Security
import Logging

struct PartialRegistration: Codable, Equatable {
    let sonarId: UUID
    let secretKey: HMACKey
}

class SecureRegistrationStorage {

    enum Error: Swift.Error {
        case invalidSecretKey
        case keychain(OSStatus)
    }

    func get() -> PartialRegistration? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: secService,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess: break
        case errSecItemNotFound: return nil
        default:
            logger.critical("Could not read registraton data from keychain due to unhandled status from SecItemCopy: \(status)")
            return nil
        }

        guard let item = result as? [String : Any],
            let data = item[kSecValueData as String] as? Data,
            let idString = item[kSecAttrAccount as String] as? String,
            let id = UUID(uuidString: idString) else {
                logger.error("No registration data in keychain")
                return nil
        }

        return PartialRegistration(sonarId: id, secretKey: HMACKey(data: data))
    }

    func set(registration: PartialRegistration) throws {
        try clear()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: secService,
            kSecAttrAccount as String: registration.sonarId.uuidString,
            kSecValueData as String: registration.secretKey.data,
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
            kSecAttrService as String: secService,
        ]
        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            logger.error("Failed to add clear registration from keychain : \(status)")
            throw Error.keychain(status)
        }
    }

}

fileprivate let secService = "registration"

// MARK: - Logging
fileprivate let logger = Logger(label: "Registration")
