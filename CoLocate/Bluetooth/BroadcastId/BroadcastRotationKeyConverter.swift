//
//  BroadcastRotationKeyConverter.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Security

import Logging

struct BroadcastRotationKeyConverter {
    func fromData(_ data: Data) throws -> SecKey {
        var scanner = ASN1Scanner(data: data)
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
}

fileprivate enum EllipticCurveErrors: Error {
    case invalidASN1
    case publicKeyConversionFailed
    case unhandledCFError(_ error: CFError)

    case couldNotSaveToKeychain(_ status: OSStatus)
    case unhandledKeychainError(_ status: OSStatus)
}


/*
 Copied with permission from Zulkhe Engineering
https://github.com/zuhlke/AppStoreConnector/blob/master/AppStoreConnector/AppStoreConnector/Sources/Crypto/ASN1Scanner.swift

 MIT License

 Copyright (c) 2020 Zuhlke Engineering Ltd

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
*/
fileprivate struct ASN1Scanner {
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

// Mark: - Logging
fileprivate let logger = Logger(label: "BTLE")
