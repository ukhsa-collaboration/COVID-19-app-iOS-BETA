//
//  OnboardingTests.swift
//  SonarUITests
//
//  Created by NHSX on 03/04/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest

class OnboardingTests: ScreenTestCase {
    
    override var screen: Screen { .onboarding }
    
    func testEntireOnboardingFlow() {
        // Start screen
        XCTAssert(startTitle.exists)
        learnMore.tap()

        // Privacy policy screen
        XCTAssert(privacyScreenTitle.exists)
        privacyCloseButton.tap()

        // returned back to the home screen
        XCTAssert(startTitle.exists)
        continueButton.tap()

        // partial post code screen
        XCTAssert(postcodeScreenTitle.exists)
        postcodeField.tap()
        postcodeField.typeText("A1\n")
        
        // Please allow us Bluetooth and Notifications screen
        XCTAssert(permissionsScreenTitle.exists)
        
        XCTAssert(notificationPermissionAlertTitle.exists)
        allowNotificationsButton.tap()
    }
}

// TODO: Change these to screen-based properties

private extension OnboardingTests {
    
    var continueButton: XCUIElement {
        app.buttons["Continue"]
    }
    
}

private extension OnboardingTests {

    var startTitle: XCUIElement {
        app.staticTexts["This NHS app does three things for you:"]
    }

    var learnMore: XCUIElement {
        app.buttons["Learn more about how the app works"]
    }
    
    var privacyScreenTitle: XCUIElement {
        app.staticTexts["How the app works"]
    }
    
    var privacyCloseButton: XCUIElement {
        app.buttons["Close"]
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
        app.staticTexts["Enter the first part of your home postcode"]
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
        app.staticTexts["“Sonar” Would Like to Send You Notifications"]
    }
    
    var allowNotificationsButton: XCUIElement {
        app.buttons["Allow"]
    }
    
}
