//
//  ConfirmRegistrationRequestTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
import CryptoKit
@testable import CoLocate

class ConfirmRegistrationRequestTests: XCTestCase {
    
    let activationCode = UUID()
    let deviceId = UUID()
    let symmetricKey = SymmetricKey(data: Data(base64Encoded: "3bLIKs9B9UqVfqGatyJbiRGNW8zTBr2tgxYJh/el7pc=")!)
    let pushToken: String = "someBase64StringWeGotFromFirebase=="

    var request: ConfirmRegistrationRequest!
    
    override func setUp() {
        request = ConfirmRegistrationRequest(activationCode: activationCode, pushToken: pushToken)
    }

    func testHttpMethod() {
        XCTAssertTrue(request.isMethodPOST)
    }
    
    func testPath() {
        XCTAssertEqual(request.path, "/api/devices")
    }
    
    func testHeaders() {
        XCTAssertEqual(request.headers.count, 2)
        XCTAssertEqual(request.headers["Accept"], "application/json")
        XCTAssertEqual(request.headers["Content-Type"], "application/json")
    }
    
    func testBody() {
        XCTAssertEqual(String(data: request.body!, encoding: .utf8)!,
"""
{"pushToken":"someBase64StringWeGotFromFirebase==","activationCode":"\(activationCode.uuidString)"}
""")
    }

    // These commented tests are valid! I just wanted to check in before lunch --RA
//    func testParseValidResponse() {
//        let responseData =
//        """
//            "id": "\(deviceId.uuidString)", "secretKey": "3bLIKs9B9UqVfqGatyJbiRGNW8zTBr2tgxYJh/el7pc="
//        """.data(using: .utf8)!
//        let response = try? request.parse(responseData)
//
//        XCTAssertEqual(response?.id, deviceId)
//        XCTAssertEqual(response?.secretKey, symmetricKey)
//    }
//
//    func testParseInvalidUUID() {
//        let responseData =
//        """
//        "id": "uuid-blabalabla", "secretKey": "3bLIKs9B9UqVfqGatyJbiRGNW8zTBr2tgxYJh/el7pc="
//        """.data(using: .utf8)!
//        let response = try? request.parse(responseData)
//
//        XCTAssertEqual(response?.id, deviceId)
//        XCTAssertEqual(response?.secretKey, symmetricKey)
//    }
//
//    func testParseInvalidSymmetricKey() {
//        let responseData =
//        """
//        "id": "\(deviceId.uuidString)", "secretKey": "random non-base64 nonsense"
//        """.data(using: .utf8)!
//        let response = try? request.parse(responseData)
//
//        XCTAssertEqual(response?.id, deviceId)
//        XCTAssertEqual(response?.secretKey, symmetricKey)
//    }

 }
