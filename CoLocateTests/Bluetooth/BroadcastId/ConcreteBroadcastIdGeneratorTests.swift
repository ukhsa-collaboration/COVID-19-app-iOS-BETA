//
//  ConcreteBroadcastIdGeneratorTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest

@testable import CoLocate


class ConcreteBroadcastIdGeneratorTests: XCTestCase {

    var subject: ConcreteBroadcastIdGenerator!
    var storage: StubbedBroadcastRotationKeyStorage!

    override func setUp() {
        subject = ConcreteBroadcastIdGenerator(storage: StubbedBroadcastRotationKeyStorage(stubbedKey: nil))
    }

    func test_it_provides_the_encrypted_result_once_given_sonar_id_and_server_public_key() {
        let storage = StubbedBroadcastRotationKeyStorage(stubbedKey: knownGoodECPublicKey())
        subject = ConcreteBroadcastIdGenerator(storage: storage)
        subject.sonarId = UUID(uuidString: "054DDC35-0287-4247-97BE-D9A3AF012E36")!

        let identifier = subject.broadcastIdentifier()

        XCTAssertNotNil(identifier)
    }

    func test_it_is_not_ready_initiially() {
        let identifier = subject.broadcastIdentifier()

        XCTAssertNil(identifier)
    }

    func test_it_is_still_not_ready_once_the_sonar_id_is_present() {
        subject.sonarId = UUID(uuidString: "054DDC35-0287-4247-97BE-D9A3AF012E36")!

        let identifier = subject.broadcastIdentifier()
        XCTAssertNotNil(identifier)
    }

    func test_it_is_still_not_ready_once_the_server_public_key_is_present() throws {
        throw XCTSkip("Not implemented until the server can give us this key")

        let storage = StubbedBroadcastRotationKeyStorage(stubbedKey: knownGoodECPublicKey())
        subject = ConcreteBroadcastIdGenerator(storage: storage)

        let identifier = subject.broadcastIdentifier()
        XCTAssertNil(identifier)
    }

    func test_it_is_not_ready_if_the_storage_throws_an_error() throws {
        throw XCTSkip("Not implemented until the server can give us this key")

        let storage = StubbedBroadcastRotationKeyStorage(shouldThrow: true)
        subject = ConcreteBroadcastIdGenerator(storage: storage)
        subject.sonarId = UUID(uuidString: "054DDC35-0287-4247-97BE-D9A3AF012E36")!

        let identifier = subject.broadcastIdentifier()

        XCTAssertNil(identifier)
    }
}

class StubbedBroadcastRotationKeyStorage: BroadcastRotationKeyStorage {

    let stubbedKey: SecKey?
    let shouldThrow: Bool

    init(stubbedKey: SecKey? = nil, shouldThrow: Bool = false) {
        self.stubbedKey = stubbedKey
        self.shouldThrow = shouldThrow
    }

    func save(keyData: Data) throws {

    }

    func read() throws -> SecKey? {
        if shouldThrow {
            throw ErrorForTest()
        }

        return stubbedKey
    }

    func clear() throws {

    }
}

private func knownGoodECPublicKey() -> SecKey {
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
