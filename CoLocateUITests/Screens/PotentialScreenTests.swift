//
//  PotentialScreenTests.swift
//  CoLocateUITests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest

class PotentialScreenTests: XCTestCase {
    
    private var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
                
        app = XCUIApplication()
        app.launchEnvironment["UI_TEST"] = "YES"
        app.launch()
    }

    func testBasics() {
        XCTAssert(title.exists)
    }
}

private extension PotentialScreenTests {
    
    var title: XCUIElement {
        app.staticTexts["Potential"]
    }
    
}
