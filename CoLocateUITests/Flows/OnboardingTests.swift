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
    
    func testEntireOnboardingFlow() {
        // Start screen
        
        startButton.tap()
        
        // Privacy screen
        
        XCTAssert(privacyScreenTitle.exists)

        #warning("FIXME this will be going away soon")
        privacyContinueButton.tap()
        
        XCTAssert(postcodeScreenTitle.exists)
        postcodeField.tap()
        postcodeField.typeText("1234\n")
        postcodeContinueButton.tap()
        
        // Permissions screen
        
        XCTAssert(permissionsScreenTitle.exists)
        
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
