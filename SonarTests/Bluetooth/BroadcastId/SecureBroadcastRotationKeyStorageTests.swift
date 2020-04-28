//
//  SecureBroadcastRotationKeyStorageTests.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
import Security

@testable import Sonar

class SecureBroadcastRotationKeyStorageTests: XCTestCase {

    let storage = SecureBroadcastRotationKeyStorage()

    override func setUp() {
        super.setUp()

        try! storage.clear()
    }

    func test_saves_the_key_and_reads_it_back() throws {
        try storage.save(publicKey: try ellipticCurveKeyForTest())

        let otherWrapper = SecureBroadcastRotationKeyStorage()
        let readKey = otherWrapper.read()

        XCTAssertNotNil(readKey)
    }

    func test_returns_nil_if_no_key_was_saved() {
        let readKey = storage.read()

        XCTAssertNil(readKey)
    }

    //MARK: - Private

    private func ellipticCurveKeyForTest() throws -> SecKey {
        let data = Data.init(base64Encoded: "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEu1f68MqDXbKeTqZMTHsOGToO4rKnPClXe/kE+oWqlaWZQv4J1E98cUNdpzF9JIFRPMCNdGOvTr4UB+BhQv9GWg==")!
        return try BroadcastRotationKeyConverter().fromData(data)
    }
}
