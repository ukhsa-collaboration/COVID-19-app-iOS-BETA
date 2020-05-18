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
        app.buttons["Yes, I have at least one of these symptoms"]
    }

    var noContinuousCoughOption: XCUIElement {
        app.buttons["No, I do not have either of these symptoms"]
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
        app.staticTexts["Your symptoms indicate you may have coronavirus"]
    }

    var bookNowAdvice: XCUIElement {
        app.staticTexts["Please book a coronavirus test immediately. Write down your reference code and phone 0800 540 4900"]
    }

}
