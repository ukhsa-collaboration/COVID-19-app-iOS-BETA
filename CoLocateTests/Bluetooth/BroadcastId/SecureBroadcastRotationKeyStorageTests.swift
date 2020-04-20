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
        let testKeyData = ellipticCurveKeyForTest()

        try storage.save(keyData: testKeyData)

        let otherWrapper = SecureBroadcastRotationKeyStorage()
        let readKey = try? otherWrapper.read()

        XCTAssertNotNil(readKey)
    }

    func test_returns_nil_if_no_key_was_saved() {
        let readKey = try? storage.read()

        XCTAssertNil(readKey)
    }

    func test_throws_when_fed_garbage_data() {
        XCTAssertThrowsError(try storage.save(keyData: Data()))
    }

    //MARK: - Private

    private func ellipticCurveKeyForTest() -> Data {
        let base64EncodedKey = "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEu1f68MqDXbKeTqZMTHsOGToO4rKnPClXe/kE+oWqlaWZQv4J1E98cUNdpzF9JIFRPMCNdGOvTr4UB+BhQv9GWg=="

        return Data.init(base64Encoded: base64EncodedKey)!
    }
}
