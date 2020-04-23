//
//  URLSessionTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class URLSessionTests: XCTestCase {

    func test_has_correct_security_configuration() throws {
        let configuration = URLSession.make().configuration
        
        if #available(iOS 13.0, *) {
            XCTAssertEqual(configuration.tlsMinimumSupportedProtocolVersion, .TLSv12)
        }
        XCTAssertEqual(configuration.tlsMinimumSupportedProtocol, .tlsProtocol12)
        XCTAssertEqual(configuration.httpCookieAcceptPolicy, .never)
        XCTAssertFalse(configuration.httpShouldSetCookies)
        XCTAssertNil(configuration.httpCookieStorage)
        XCTAssertNil(configuration.urlCache)
    }
}
