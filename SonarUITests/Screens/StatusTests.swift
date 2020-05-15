//
//  StatusTests.swift
//  SonarUITests
//
//  Created by NHSX on 04/05/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest

class StatusTests: ScreenTestCase {

    override var screen: Screen { .status }

    func testSelfDiagnosisPositiveFlow() {
        // Blue advice screen
        XCTAssert(blueAdvice.exists)

        feelUnwellButton.tap()

        // Symptom selection screens
        highTemperatureOption.tap()
        continueButton.tap()

        continuousCoughOption.tap()
        continueButton.tap()

        // Start date screen
        startDateButton.tap()
        continueButton.tap()

        // Data submission screen
        accurateConfirmationToggle.tap()
        submitButton.tap()

        // Self diagnosed advice screen
        XCTAssert(selfDiagnosedAdvice.exists)
        XCTAssert(bookNowAdvice.exists)

        eightDaysLater()

        XCTAssert(questionnairePopup.exists)
        questionnaireUpdateButton.tap()
        cancelButton.tap()

        // questionnaire reappears if the user cancels
        XCTAssert(questionnairePopup.exists)
        questionnaireUpdateButton.tap()

        // if the user still has symptoms...
        highTemperatureOption.tap();
        continueButton.tap();
        continuousCoughOption.tap();
        submitButton.tap();

        // they are told to continue isolating
        XCTAssert(selfDiagnosedAdvice.exists)

        eightDaysLater()

        XCTAssert(questionnairePopup.exists)
        questionnaireUpdateButton.tap()

        // if the user only has a cough...
        noHighTemperatureOption.tap();
        continueButton.tap();
        continuousCoughOption.tap();
        submitButton.tap();

        // ...they are told to return to "current advice"...
        XCTAssert(coughAdvice.exists)
        closeButton.tap();

        eightDaysLater()

        // ...and are not reminded again
        XCTAssertFalse(questionnairePopup.exists)
    }

    func testSelfDiagnosisNegativeFlow() {
        // Blue advice screen
        XCTAssert(blueAdvice.exists)

        feelUnwellButton.tap()

        // Symptom selection screens
        noHighTemperatureOption.tap()
        continueButton.tap()

        noContinuousCoughOption.tap()
        continueButton.tap()

        // No symptom advice screen
        XCTAssert(noSymptomsAdvice.exists)
        doneButton.tap()

        // Blue advice screen
        XCTAssert(blueAdvice.exists)
    }
}

private extension ScreenTestCase {
    func eightDaysLater() {
        // close app
        XCUIDevice.shared.press(.home)

        // open app 8 days later
        // (test harness ensures that 8 days pass whenever we close the app)

        XCUIApplication().activate()
        usleep(500000) // wait for app opening animation
    }

    var blueAdvice: XCUIElement {
        app.staticTexts["Follow the current advice to stop the spread of coronavirus"]
    }

    var feelUnwellButton: XCUIElement {
        app.staticTexts["I feel unwell"]
    }

    var highTemperatureOption: XCUIElement {
        app.buttons["Yes, I have a high temperature"]
    }

    var noHighTemperatureOption: XCUIElement {
        app.buttons["No, I do not have a high temperature"]
    }

    var continuousCoughOption: XCUIElement {
        app.buttons["Yes, I have a new continuous cough"]
    }

    var noContinuousCoughOption: XCUIElement {
        app.buttons["No, I do not have a new continuous cough"]
    }

    var continueButton: XCUIElement {
        app.buttons["Continue"]
    }

    var noSymptomsAdvice: XCUIElement {
        app.staticTexts["You do not appear to have coronavirus symptoms"]
    }

    var doneButton: XCUIElement {
        app.buttons["Done"]
    }

    var startDateButton: XCUIElement {
        app.buttons["Select start date"]
    }

    var accurateConfirmationToggle: XCUIElement {
        app.switches["Please toggle the switch to confirm the information you entered is accurate"]
    }

    var submitButton: XCUIElement {
        app.buttons["Submit"]
    }

    var selfDiagnosedAdvice: XCUIElement {
        app.staticTexts["Your symptoms indicate you may have coronavirus. Please self-isolate and apply for a test."]
    }

    var bookNowAdvice: XCUIElement {
        app.staticTexts["Please book a coronavirus test immediately. Write down your reference code and phone 0800 540 4900"]
    }

    var questionnairePopup: XCUIElement {
        app.staticTexts["How are you feeling today?"]
    }

    var questionnaireUpdateButton: XCUIElement {
        app.buttons["Update my symptoms"]
    }

    var cancelButton: XCUIElement {
        app.buttons["Cancel"]
    }

    var coughAdvice: XCUIElement {
        app.staticTexts["Although you still have a continuous cough, you can now follow the current advice."]
    }

    var closeButton: XCUIElement {
        app.buttons["Close"]
    }

}
