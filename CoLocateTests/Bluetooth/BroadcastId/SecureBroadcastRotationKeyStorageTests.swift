//
//  SecureBroadcastRotationKeyStorageTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
import Security

@testable import CoLocate

class SecureBroadcastRotationKeyStorageTests: XCTestCase {

    let storage = SecureBroadcastRotationKeyStorage()

    override func setUp() {
        super.setUp()

        try! storage.clear()
    }

    func test_saves_the_key_and_reads_it_back() throws {
        let testCertificateData = certificateForTest()
        try storage.save(certificate: testCertificateData)

        let otherStorage = SecureBroadcastRotationKeyStorage()
        let keyFromKeychain = try? otherStorage.read()

        XCTAssertNotNil(keyFromKeychain)

        let data = SecKeyCopyExternalRepresentation(keyFromKeychain!, nil)! as Data
        XCTAssertEqual(65, data.count)
        XCTAssertEqual(expectedPublicKeyBytes, data.base64EncodedString())
    }

    func test_returns_nil_if_no_key_was_saved() {
        let readKey = try? storage.read()

        XCTAssertNil(readKey)
    }

    //MARK: - Private

    let expectedPublicKeyBytes = "BLtX+vDKg12ynk6mTEx7Dhk6DuKypzwpV3v5BPqFqpWlmUL+CdRPfHFDXacxfSSBUTzAjXRjr06+FAfgYUL/Rlo="

    private func certificateForTest() -> Data {
        let base64EncodedCertificate = """
MIIBCTCBsAIJAIhNPYlAcwsxMAoGCCqGSM49BAMCMA0xCzAJBgNVBAYTAkdCMB4XDTIwMDQxNzExNDYxNloXDTIyMDQxNzExNDYxNlowDTELMAkGA1UEBhMCR0IwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAAS7V/rwyoNdsp5OpkxMew4ZOg7isqc8KVd7+QT6haqVpZlC/gnUT3xxQ12nMX0kgVE8wI10Y69OvhQH4GFC/0ZaMAoGCCqGSM49BAMCA0gAMEUCIC1Ju3i9iKLNfs9W3cX/OCqZWqk/5KXnE2V9NvWmM6oUAiEAtYkPZsV8sfDAMYw03FIcMha3RfisUS88RZXEp1g1KAU=
"""

        return Data(base64Encoded: base64EncodedCertificate)!
    }
}
