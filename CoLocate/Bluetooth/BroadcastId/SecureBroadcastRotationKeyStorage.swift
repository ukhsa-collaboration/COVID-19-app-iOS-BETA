//
//  SecureBroadcastRotationKeyStorage.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Security

import Logging

protocol BroadcastRotationKeyStorage {
    func save(certificate: Data) throws
    func read() throws -> SecKey?
    func clear() throws
}

struct SecureBroadcastRotationKeyStorage: BroadcastRotationKeyStorage {

    private let publicKeyTag = "uk.nhs.nhsx.colocate.sonar.public_key"

    enum Error: Swift.Error {
        case invalidCertificate
        case keychain(OSStatus)
    }

    func save(certificate: Data) throws {
        guard let publicKey = extractPublicKeyFrom(certificate) else {
            logger.info("Could not save public key from certificate")
            throw Error.invalidCertificate
        }

        let status = saveInKeychain(publicKey)
        guard status == errSecSuccess else {
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

    // MARK: - Private

    func extractPublicKeyFrom(_ certificate: Data) -> SecKey? {
        // shamelessly stolen from this blog post that explains importing public keys on iOS
        // https://digitalleaves.com/blog/2015/10/sharing-public-keys-between-ios-and-the-rest-of-the-world/

        guard let certRef = SecCertificateCreateWithData(nil, certificate as CFData) else {
            logger.critical("Could not create certificate from data")
            return nil
        }

        var secTrustMaybe: SecTrust?
        let secTrustStatus = SecTrustCreateWithCertificates(certRef, nil, &secTrustMaybe)
        guard secTrustStatus == errSecSuccess else {
            logger.critical("Could not create trust from certificate. Status: \(secTrustStatus)")
            return nil
        }

        guard let secTrust = secTrustMaybe else {
            logger.critical("Could not create certificate. secTrust is nil")
            return nil
        }

        var resultType: SecTrustResultType = .invalid
        let evaluateStatus = SecTrustEvaluate(secTrust, &resultType)
        guard evaluateStatus == errSecSuccess else {
            logger.critical("Could not evaluate sec trust. Status: \(evaluateStatus)")
            return nil
        }

        return SecTrustCopyPublicKey(secTrust)
    }

    func saveInKeychain(_ publicKey: SecKey) -> OSStatus {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: publicKeyTag,
            kSecValueRef as String: publicKey as Any,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]

        return SecItemAdd(query as CFDictionary, nil)
    }
}

fileprivate let logger = Logger(label: "BTLE")
