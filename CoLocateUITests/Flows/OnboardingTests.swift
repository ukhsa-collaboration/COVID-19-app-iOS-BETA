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
    
    func testAuthorizingEverything() {
        startButton.tap()
        XCTAssert(permissionsScreenTitle.exists)
        
        XCTAssertFalse(continueButton.isEnabled)
        XCTAssertFalse(allowDataSharingSwitch.boolValue)
        
        #warning("Fix accessibility of the switch.")
        // There are multiple issues with the current implementation:
        // * The “element” should encompass both the text and the switch
        // * Probably additional hinting is required to clarify the behaviour
        allowDataSharingSwitch.tap()
        
        XCTAssert(allowDataSharingSwitch.boolValue)
        XCTAssert(continueButton.isEnabled)
        
        continueButton.tap()
        
        XCTAssert(recodedConsentTitle.exists)
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
    
    var allowDataSharingSwitch: XCUIElement {
        app.switches["Allow Data Sharing"]
    }
    
}

private extension OnboardingTests {
    
    var recodedConsentTitle: XCUIElement {
        app.staticTexts["Recorded data sharing consent"]
    }
    
}
