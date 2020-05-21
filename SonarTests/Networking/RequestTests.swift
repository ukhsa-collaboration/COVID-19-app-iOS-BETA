//
//  RequestTests.swift
//  SonarTests
//
//  Created by NHSX on 23/04/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

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

    func testSonarAppVersionHeaderIsSetToCurrentBuildNumber() throws {
        let urlRequest = request.urlRequest()
        let headers = try XCTUnwrap(urlRequest.allHTTPHeaderFields)
        XCTAssertTrue(headers["X-Sonar-App-Version"] != nil, "build should be present")
        XCTAssertTrue(Int(headers["X-Sonar-App-Version"]!) != nil, "build should be a valid number")
    }

    func testSonarFoundationHeaderValueOverridesValuesManuallySet() throws {
        request.headers["X-Sonar-Foundation"] = "other-value"
        let urlRequest = request.urlRequest()
        let headers = try XCTUnwrap(urlRequest.allHTTPHeaderFields)
        XCTAssertEqual(headers["Request-Header"], "Request-Value", "Other headers set by request should be preserved")
        
        XCTAssertEqual(headers["X-Sonar-Foundation"], "sonar-header-value")
    }

    func testRelativePath() {
        request.urlable = .path("/foo/bar/baz")

        let urlRequest = request.urlRequest()

        XCTAssertEqual(urlRequest.url?.path, "/foo/bar/baz")
    }

    func testAbsolutePath() {
        request.urlable = .url(URL(string: "https://example.com/foo/bar/baz")!)

        let urlRequest = request.urlRequest()

        XCTAssertEqual(urlRequest.url?.absoluteString, "https://example.com/foo/bar/baz")
    }

}

private struct MockRequest: Request {

    var method = HTTPMethod.get
    var headers = ["Request-Header": "Request-Value"]
    var urlable = Urlable.path(UUID().uuidString)
    var sonarHeaderValue = "sonar-header-value"

    func parse(_ data: Data) throws -> Data {
        data
    }
}
