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

    func test_is_configured_with_a_proper_URL() throws {
        let url = URLSession.shared.baseURL

        XCTAssertNotNil(url)
    }
}
