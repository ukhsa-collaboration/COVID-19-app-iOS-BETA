//
//  RequstTests.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class RequestTests: XCTestCase {
    
    private var request: MockRequest!
    
    override func setUp() {
        super.setUp()
        
        request = MockRequest()
    }
    
    func testSonarFoundationHeaderIsAlwaysAdded() throws {
        let urlRequest = request.urlRequest()
        let headers = try XCTUnwrap(urlRequest.allHTTPHeaderFields)
        XCTAssertEqual(headers["Request-Header"], "Request-Value", "Other headers set by request should be preserved")
        XCTAssertEqual(headers["X-Sonar-Foundation"], "sonar-header-value")
    }

    func testSonarFoundationHeaderValueOverridesValuesManuallySet() throws {
        request.headers["X-Sonar-Foundation"] = "other-value"
        let urlRequest = request.urlRequest()
        let headers = try XCTUnwrap(urlRequest.allHTTPHeaderFields)
        XCTAssertEqual(headers["Request-Header"], "Request-Value", "Other headers set by request should be preserved")
        
        XCTAssertEqual(headers["X-Sonar-Foundation"], "sonar-header-value")
    }

}

private struct MockRequest: Request {

    var method = HTTPMethod.get
    var headers = ["Request-Header": "Request-Value"]
    var path = UUID().uuidString
    var sonarHeaderValue = "sonar-header-value"

    func parse(_ data: Data) throws -> Data {
        data
    }
}
