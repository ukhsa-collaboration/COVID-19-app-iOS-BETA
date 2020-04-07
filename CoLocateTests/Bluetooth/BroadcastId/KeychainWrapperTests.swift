//
//  KeychainWrapperTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
import Security

@testable import CoLocate

class KeychainWrapperTests: XCTestCase {

    let keychainWrapper = BroadcastIdRotationKeychainWrapper.shared

    override func setUp() {
        super.setUp()

        try! keychainWrapper.clear()
    }

    func test_saves_the_key_and_reads_it_back() throws {
        let testCertificateData = ellipticCurveKeyForTest()

        try! keychainWrapper.save(keyData: testCertificateData)

        let otherWrapper = BroadcastIdRotationKeychainWrapper()
        let readKey = try? otherWrapper.read()
        XCTAssertNotNil(readKey)

        let data = SecKeyCopyExternalRepresentation(readKey!, nil)! as Data
        XCTAssertEqual(testCertificateData, data)
    }

    func test_returns_nil_if_no_key_was_saved() {
        let readKey = try? keychainWrapper.read()

        XCTAssertNil(readKey)
    }

    //MARK: - Private

    private func ellipticCurveKeyForTest() -> Data {
        let base64EncodedKey = "BDSTjw7/yauS6iyMZ9p5yl6i0n3A7qxYI/3v+6RsHt8o+UrFCyULX3fKZuA6ve+lH1CAItezr+Tk2lKsMcCbHMI="

        return Data.init(base64Encoded: base64EncodedKey)!
    }
}
