//
//  SignedRequestTests.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class SecureRequestTests: XCTestCase {

    var request: SampleSecureRequest!
    
    override func setUp() {
        let keyData = Data(base64Encoded: "Gqacz+VE6uuZy1uc4oTG/A+LAS291mXN+J5opDSNYys=")!

        request = SampleSecureRequest(key: keyData, text: "Hello, nurse!", date: Date(timeIntervalSince1970: 1))
        super.setUp()
    }

    // To double-check this HMAC from the command line...
    // echo -n '1970-01-01T00:00:01ZHello, nurse!' | openssl dgst -sha256 -hmac $(echo -n "Gqacz+VE6uuZy1uc4oTG/A+LAS291mXN+J5opDSNYys=" | base64 -d) | xxd -r -p | base64
    func testRequestHasSignatureHeader() {
        XCTAssertEqual(request.headers["Sonar-Message-Signature"], "bbDadktBVp2+GOpKisETJISycO+C0FqwMl2wuAUZU+o=")
    }
    
    func testRequestHasTimestampHeader() {
        XCTAssertEqual(request.headers["Sonar-Request-Timestamp"]!, "1970-01-01T00:00:01Z")
    }
    
    func testRequestHasOriginalHeaders() {
        XCTAssertEqual(request.headers["Favourite-Colour"], "Puce")
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
    
    init(key: Data, text: String, date: Date = Date()) {
        let data = text.data(using: .utf8)!
        method = HTTPMethod.post(data: data)
        path = "/api/sample"
        let headers = ["Favourite-Colour": "Puce"]
        
        super.init(key, data, headers, date)
    }

    func parse(_ data: Data) throws -> Void {
        
    }
}
