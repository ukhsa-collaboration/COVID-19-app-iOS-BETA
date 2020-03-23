//
//  SignedRequestTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
import CryptoKit
@testable import CoLocate

class SignedRequestTests: XCTestCase {

    var request: SampleSecureRequest!
    
    override func setUp() {
        let keyData = Data(base64Encoded: "Gqacz+VE6uuZy1uc4oTG/A+LAS291mXN+J5opDSNYys=")!

        request = SampleSecureRequest(key: SymmetricKey(data: keyData), text: "Hello, nurse!", date: Date(timeIntervalSince1970: 1))
    }

    func testRequestHasSignatureHeader() {
        XCTAssertEqual(request.headers["X-Sonar-Message-Signature"], "bbDadktBVp2+GOpKisETJISycO+C0FqwMl2wuAUZU+o=")
    }
    
    func testRequestHasTimestampHeader() {
        XCTAssertEqual(request.headers["X-Sonar-Message-Timestamp"], "1970-01-01T00:00:01Z")
    }
    
    func testRequestHasOriginalHeaders() {
        XCTAssertEqual(request.headers["X-Favourite-Colour"], "Puce")
    }
    
    func testHttpMethod() {
        XCTAssertTrue(request.isMethodPOST)
    }
    
    func testData() {
        XCTAssertEqual(String(data: request.body!, encoding: .utf8), "Hello, nurse!")
    }

}

class SampleSecureRequest: SecureRequest, Request {

    typealias ResponseType = Void
    
    let method: HTTPMethod
    let path: String
    
    init(key: SymmetricKey, text: String, date: Date = Date()) {
        let data = text.data(using: .utf8)!
        method = HTTPMethod.post(data: data)
        path = "/api/sample"
        let headers = ["X-Favourite-Colour": "Puce"]
        
        super.init(key, data, headers, date)
    }

    func parse(_ data: Data) throws -> Void {
        
    }
}
