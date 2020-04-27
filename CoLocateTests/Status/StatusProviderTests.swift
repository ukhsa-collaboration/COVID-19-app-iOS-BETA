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

    var persisting: PersistenceDouble!
    var provider: StatusProvider!

    override func setUp() {
        super.setUp()

        persisting = PersistenceDouble()
        provider = StatusProvider(persisting: persisting)
    }

    func testDefault() {
        XCTAssertEqual(provider.status, .blue)
    }

    func testPotentiallyExposed() {
        persisting.potentiallyExposed = true

        XCTAssertEqual(provider.status, .amber)
    }

}
