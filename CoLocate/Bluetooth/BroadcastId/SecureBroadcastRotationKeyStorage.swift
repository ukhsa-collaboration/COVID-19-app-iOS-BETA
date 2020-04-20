//
//  SecureBroadcastRotationKeyStorage.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Security
import CommonCrypto

import Logging

protocol BroadcastRotationKeyStorage {
    func save(keyData: Data) throws
    func read() throws -> SecKey?
    func clear() throws
}

struct SecureBroadcastRotationKeyStorage: BroadcastRotationKeyStorage {

    private let publicKeyTag = "uk.nhs.nhsx.colocate.sonar.public_key"

    func save(keyData: Data) throws {
        let publicKey = try extractPublicKey(from: keyData)
        let status = saveToKeychain(publicKey)

        guard status == errSecSuccess || status == errSecDuplicateItem else {
            logger.error("Failed to add BTLE rotation key to keychain: \(status)")
            throw EllipticCurveErrors.couldNotSaveToKeychain(status)
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
            throw EllipticCurveErrors.unhandledKeychainError(status)
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
            throw EllipticCurveErrors.unhandledKeychainError(status)
        }
    }

    // MARK: - Private

    private func extractPublicKey(from keyData: Data) throws -> SecKey {
        var scanner = ASN1Scanner(data: keyData)
        try scanner.scanSequenceHeader()

        let algorithmIdentifierLength = try scanner.scanSequenceHeader()
        scanner.stream = scanner.stream.dropFirst(algorithmIdentifierLength)

        let publicKey = try scanner.scanBitString()
        let publicKeyIsUncompressed = publicKey.starts(with: [0x00, 0x04])
        guard publicKeyIsUncompressed else {
            logger.critical("Invalid ASN1 for public key. Starts with \(publicKey[0])")
            throw EllipticCurveErrors.invalidASN1
        }

        let x = publicKey[publicKey.startIndex+2..<publicKey.startIndex+2+32]
        let y = publicKey[publicKey.startIndex+2+32..<publicKey.startIndex+2+32+32]
        let data = Data([4]) + x + y

        var error: Unmanaged<CFError>?
        let attrs = [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass:  kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits: 256
        ] as CFDictionary

        guard let privateKey = SecKeyCreateWithData(data as CFData, attrs, &error) else {
            logger.critical("Encountered error creating public key from data: \(error!.takeRetainedValue().localizedDescription)")
            throw EllipticCurveErrors.publicKeyConversionFailed
        }

        return privateKey
    }

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

fileprivate let logger = Logger(label: "BTLE")

fileprivate enum EllipticCurveErrors: Error {
    case invalidASN1
    case publicKeyConversionFailed
    case unhandledCFError(_ error: CFError)

    case couldNotSaveToKeychain(_ status: OSStatus)
    case unhandledKeychainError(_ status: OSStatus)
}

struct ASN1Scanner {
    private struct Tag {
        var rawValue: UInt8
        static let integer = Tag(rawValue: 0x02)
        static let bitString = Tag(rawValue: 0x03)
        static let octet = Tag(rawValue: 0x04)
        static let objectIdentifier = Tag(rawValue: 0x06)
        static let sequence = Tag(rawValue: 0x30)
        static func tagged(_ value: UInt8) -> Tag {
            return Tag(rawValue: value + 0xa0)
        }
    }

    private enum Errors: Error {
        case invalidStream
    }

    var stream: Data

    init(data: Data) {
        self.stream = data
    }

    @discardableResult
    mutating func scanSequenceHeader() throws -> Int {
        return try scanLength(for: .sequence)
    }

    @discardableResult
    mutating func scanTagHeader(_ value: UInt8) throws -> Int {
        return try scanLength(for: .tagged(value))
    }

    @discardableResult
    mutating func scanInteger() throws -> Data {
        return try scanData(for: .integer)
    }

    @discardableResult
    mutating func scanBitString() throws -> Data {
        return try scanData(for: .bitString)
    }

    @discardableResult
    mutating func scanOctet() throws -> Data {
        return try scanData(for: .octet)
    }

    @discardableResult
    mutating func scanObjectIdentifier() throws -> Data {
        return try scanData(for: .objectIdentifier)
    }

    @discardableResult
    mutating func scanTag(_ value: UInt8) throws -> Data {
        return try scanData(for: .tagged(value))
    }

    @discardableResult
    private mutating func scanData(for tag: Tag) throws -> Data {
        let length = try scanLength(for: tag)

        defer {
            stream = stream.dropFirst(length)
        }
        return stream.prefix(length)
    }

    @discardableResult
    private mutating func scanLength(for tag: Tag) throws -> Int {
        guard stream.popFirst() == tag.rawValue, !stream.isEmpty else {
            throw Errors.invalidStream
        }

        let first = stream.popFirst()!
        let length: Int
        if first & 0x80 == 0x00 {
            length = Int(first)
        } else {
            let lenghOfLength = Int(first & 0x7F)
            guard stream.count >= lenghOfLength else {
                throw Errors.invalidStream
            }

            var result = 0
            for _ in 0..<lenghOfLength {
                result = 256 * result + Int(stream.popFirst()!)
            }
            length = result
        }

        guard stream.count >= length else {
            throw Errors.invalidStream
        }

        return length
    }

}

