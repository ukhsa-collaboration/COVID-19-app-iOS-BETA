//
//  KeychainWrapper.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Security

import Logging

protocol KeychainWrapper {
    func save(keyData: Data) throws
    func read() throws -> SecKey?
    func clear() throws
}

struct BroadcastIdRotationKeychainWrapper: KeychainWrapper {
    static let shared = BroadcastIdRotationKeychainWrapper()

    private let publicKeyTag = "uk.nhs.nhsx.colocate.sonar.public_key"

    enum Error: Swift.Error {
        case invalidKeyData
        case keychain(OSStatus)
    }

    func save(keyData: Data) throws {
        let keyDict : [NSObject:NSObject] = [
           kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
           kSecAttrKeyClass: kSecAttrKeyClassPublic,
           kSecAttrKeySizeInBits: NSNumber(value: 256),
           kSecReturnPersistentRef: true as NSObject
        ]

        var error: Unmanaged<CFError>?
        let publicKey = SecKeyCreateWithData(keyData as CFData, keyDict as CFDictionary, &error)
        guard error == nil else {
            logger.critical("invalid key data \(error.debugDescription)")
            throw Error.invalidKeyData
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: publicKeyTag,
            kSecValueRef as String: publicKey as Any,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess || status == errSecDuplicateItem else {
            logger.error("Failed to add BTLE rotation key to keychain: \(status)")
            throw Error.keychain(status)
        }
    }

    func read() throws -> SecKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: publicKeyTag,
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
            kSecReturnRef as String: true,
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            return (result as! SecKey)
        case errSecItemNotFound:
            logger.error("asked to read BTLE rotation key but it was not found")
            return nil
        default:
            logger.critical("Unhandled status from SecItemCopy: \(status)")
            throw Error.keychain(status)
        }
    }

    func clear() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String : publicKeyTag,
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
        ]
        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            logger.error("Failed to clear saved BTLE rotation key from keychain : \(status)")
            throw Error.keychain(status)
        }
    }
}

fileprivate let logger = Logger(label: "BTLE")
