//
//  PotentialScreenTests.swift
//  CoLocateUITests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest

class PotentialScreenTests: ScreenTestCase {
    
    override var screen: Screen { .potential }
    
    func testBasics() {
        XCTAssert(title.exists)
    }
}

private extension PotentialScreenTests {
    
    var title: XCUIElement {
        app.navigationBars["Potential"]
    }
    
}
