//
//  StatusProviderTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class StatusProviderTests: XCTestCase {

    var provider: StatusProvider!

    override func setUp() {
        super.setUp()

        provider = StatusProvider()
    }

    func testDefault() {
        XCTAssertEqual(provider.status, .blue)
    }

}
