//
//  BroadcastRotationKeyConverterTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest

@testable import CoLocate

class BroadcastRotationKeyConverterTests: XCTestCase {

    var converter: BroadcastRotationKeyConverter!

    override func setUp() {
        converter = BroadcastRotationKeyConverter()
    }

    func testConvertsKnownGoodBytesIntoAPublicKey() throws {
        let testKeyData = ellipticCurveKeyForTest()

        let key = try converter.fromData(testKeyData)

        XCTAssertNotNil(key)
    }

    func testThrowsWhenBytesDoNotRessembleAPublicKey() throws {
        XCTAssertThrowsError(try converter.fromData(Data()))
    }

    //MARK: - Private

    private func ellipticCurveKeyForTest() -> Data {
        let base64EncodedKey = "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEu1f68MqDXbKeTqZMTHsOGToO4rKnPClXe/kE+oWqlaWZQv4J1E98cUNdpzF9JIFRPMCNdGOvTr4UB+BhQv9GWg=="

        return Data.init(base64Encoded: base64EncodedKey)!
    }
}
