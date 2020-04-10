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
        // Start screen
        
        startButton.tap()
        
        // Privacy screen
        
        XCTAssert(privacyScreenTitle.exists)
        
        XCTAssertFalse(privacyContinueButton.isEnabled)
        XCTAssertFalse(allowDataSharingSwitch.boolValue)
        
        #warning("Fix accessibility of the switch.")
        // There are multiple issues with the current implementation:
        // * The “element” should encompass both the text and the switch
        // * Probably additional hinting is required to clarify the behaviour
        allowDataSharingSwitch.tap()
        
        XCTAssert(allowDataSharingSwitch.boolValue)
        XCTAssert(privacyContinueButton.isEnabled)
        
        privacyContinueButton.tap()
        
        XCTAssert(postcodeScreenTitle.exists)
        postcodeField.tap()
        postcodeField.typeText("1234\n")
        postcodeContinueButton.tap()
        
        // Permissions screen
        
        XCTAssert(permissionsScreenTitle.exists)
        permissionContinueButton.tap()
        
        XCTAssert(notificationPermissionAlertTitle.exists)
        allowNotificationsButton.tap()
    }
}

// TODO: Change these to screen-based properties

private extension OnboardingTests {
    
    var startButton: XCUIElement {
        app.buttons["Start now"]
    }
    
}

private extension OnboardingTests {
    
    var privacyScreenTitle: XCUIElement {
        app.staticTexts["How this app works"]
    }
    
    var privacyContinueButton: XCUIElement {
        app.buttons["Continue"]
    }
    
    var allowDataSharingSwitch: XCUIElement {
        app.switches["Allow Data Sharing"]
    }
    
}

private extension OnboardingTests {
    
    var permissionsScreenTitle: XCUIElement {
        app.staticTexts["Set up app permissions"]
    }
    
    var permissionContinueButton: XCUIElement {
        app.buttons["Continue"]
    }
    
}

private extension OnboardingTests {
    
    var postcodeScreenTitle: XCUIElement {
        app.staticTexts["Enter your post code"]
    }
    
    var postcodeField: XCUIElement {
        app.textFields["Post code"]
    }
    
    var postcodeContinueButton: XCUIElement {
        app.buttons["Continue"]
    }
    
}

private extension OnboardingTests {
    
    var notificationPermissionAlertTitle: XCUIElement {
        app.staticTexts["“CoLocate” Would Like to Send You Notifications"]
    }
    
    var allowNotificationsButton: XCUIElement {
        app.buttons["Allow"]
    }
    
}
