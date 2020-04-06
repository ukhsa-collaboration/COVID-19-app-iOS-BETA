//
//  OnboardingTests.swift
//  CoLocateUITests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest

class OnboardingTests: ScreenTestCase {
    
    override var screen: Screen { .onboarding }
    
    func testBasics() {
        XCTAssert(startButton.exists)
    }
    
    func testAuthorizingEverything() {
        startButton.tap()
        XCTAssert(permissionsScreenTitle.exists)
        XCTAssert(continueButton.exists)
        XCTAssertFalse(continueButton.isEnabled)
    }
}

// TODO: Change these to screen-based properties

private extension OnboardingTests {
    
    var startButton: XCUIElement {
        app.buttons["Start now"]
    }
    
}

private extension OnboardingTests {
    
    var permissionsScreenTitle: XCUIElement {
        app.staticTexts["How this app works"]
    }
    
    var continueButton: XCUIElement {
        app.buttons["Continue"]
    }
    
}
