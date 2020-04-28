//
//  BroadcastRotationKeyConverterTests.swift
//  SonarTests
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
        let input = Data(base64Encoded: "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEu1f68MqDXbKeTqZMTHsOGToO4rKnPClXe/kE+oWqlaWZQv4J1E98cUNdpzF9JIFRPMCNdGOvTr4UB+BhQv9GWg==")!
        
        let key = try converter.fromData(input)

        XCTAssertNotNil(key)
        
        var error: Unmanaged<CFError>?
        guard let cfdata = SecKeyCopyExternalRepresentation(key, &error) else {
            XCTFail("Could not extract key representation: \(String(describing: error))")
            return
        }
        
        let b64key = (cfdata as Data).base64EncodedString()
        XCTAssertEqual(b64key, "BLtX+vDKg12ynk6mTEx7Dhk6DuKypzwpV3v5BPqFqpWlmUL+CdRPfHFDXacxfSSBUTzAjXRjr06+FAfgYUL/Rlo=")
           let data:Data = cfdata as Data
           let b64Key = data.base64EncodedString()
            print("\(b64Key)")
    }

    func testThrowsWhenBytesDoNotRessembleAPublicKey() throws {
        XCTAssertThrowsError(try converter.fromData(Data()))
    }
}
