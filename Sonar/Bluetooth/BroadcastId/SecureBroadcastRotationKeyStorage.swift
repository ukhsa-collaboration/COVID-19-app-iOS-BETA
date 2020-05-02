//
//  SecureBroadcastRotationKeyStorage.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Security
import CommonCrypto

import Logging

protocol BroadcastRotationKeyStorage {
    func save(publicKey: SecKey) throws
    func save(broadcastId: Data, date: Date)
    func readBroadcastId() -> (Data, Date)?
    func read() -> SecKey?
    func clear() throws
}

struct SecureBroadcastRotationKeyStorage: BroadcastRotationKeyStorage {

    private let publicKeyTag = "uk.nhs.nhsx.sonar.public_key"
    private let broadcastIdKeyTag = "uk.nhs.nhsx.sonar.broadcast_id"
    private let broadcastIdDateKeyTag = "uk.nhs.nhsx.sonar.broadcast_id_date"

    func save(publicKey: SecKey) throws {
        let status = saveToKeychain(publicKey)

        guard status == errSecSuccess || status == errSecDuplicateItem else {
            logger.error("Failed to add BTLE rotation key to keychain: \(status)")
            throw KeychainErrors.couldNotSaveToKeychain(status)
        }
    }
    
    func save(broadcastId: Data, date: Date) {
        // TODO: Should be in the keychain? Or isn't it important, we're broadcasting it anyway!
        UserDefaults.standard.set(broadcastId, forKey: broadcastIdKeyTag)
        UserDefaults.standard.set(date, forKey: broadcastIdDateKeyTag)
    }
    
    func readBroadcastId() -> (Data, Date)? {
        guard let data = UserDefaults.standard.data(forKey: broadcastIdKeyTag), let date = UserDefaults.standard.object(forKey: broadcastIdDateKeyTag) as? Date else {
            return nil
        }
        
        return (data, date)
    }
    
    func read() -> SecKey? {
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
            logger.critical("Could not read broadcast rotation key: Unhandled status from SecItemCopy: \(status)")
            return nil
        }
    }

    func clear() throws {
        UserDefaults.standard.removeObject(forKey: broadcastIdKeyTag)
        UserDefaults.standard.removeObject(forKey: broadcastIdDateKeyTag)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String : publicKeyTag,
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
        ]
        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            logger.error("Failed to clear saved BTLE rotation key from keychain : \(status)")
            throw KeychainErrors.unhandledKeychainError(status)
        }
    }

    // MARK: - Private

    private func saveToKeychain(_ publicKey: SecKey) -> OSStatus {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: publicKeyTag,
            kSecValueRef as String: publicKey as Any,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]

        return SecItemAdd(query as CFDictionary, nil)
    }
}

fileprivate enum KeychainErrors: Error {
    case couldNotSaveToKeychain(_ status: OSStatus)
    case unhandledKeychainError(_ status: OSStatus)
}


fileprivate let logger = Logger(label: "BTLE")
