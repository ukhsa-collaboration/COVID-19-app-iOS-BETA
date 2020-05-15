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
        StatusOkPage(app)
            .assert { $0.hasStatusOkHeading }
            .tapFeelUnwell()

            .tapTemperatureOption().tapContinue()
            .tapCoughOption().tapContinue()
            .tapStartDateButton().tapContinue()
            .tapAccurateConfirmationToggle().tapSubmit()

            .assert { $0.hasStatusSymptomaticHeading }
            .assert { $0.hasBookNowAdvice }

            // waits for 7 days then starts asking user for updates
            .eightDaysLater()

            .checkinQuestionnairePopup
            .assert { $0.isShowingCheckinPrompt }
            .tapUpdateSymptoms()

            // questionnaire reappears if the user cancels
            .tapCancel()
            .assert { $0.isShowingCheckinPrompt }
            .tapUpdateSymptoms()

            // if the user still has symptoms...
            .tapTemperatureOption().tapContinue()
            .tapCoughOption().tapSubmit()

            // they are told to continue isolating
            .expectNoAdvicePopup()
            .assert { $0.hasStatusSymptomaticHeading }

            .eightDaysLater()

            .checkinQuestionnairePopup
            .assert { $0.isShowingCheckinPrompt }
            .tapUpdateSymptoms()

            // if the user only has a cough...
            .tapNoTemperatureOption().tapContinue()
            .tapCoughOption().tapSubmit()

            // ...they are told to return to "current advice"...
            .checkAndDismissCoughAdvice()
            .assert { $0.hasStatusOkHeading }

            .eightDaysLater()

            // ...and are not reminded again
            .checkinQuestionnairePopup
            .assert { !$0.isShowingCheckinPrompt }
    }

    func testSelfDiagnosisNegativeFlow() {
        StatusOkPage(app)
            .assert { $0.hasStatusOkHeading }
            .tapFeelUnwell()

            .tapNoTemperatureOption().tapContinue()
            .tapNoCoughOption().tapContinue()

            .assert { $0.hasNoSymptoms }
            .tapDone()

            .assert { $0.hasStatusOkHeading }
    }
}

protocol PageChainable { }

extension PageChainable {
    @discardableResult
    func then(block: (Self) -> Void) -> Self {
        block(self)
        return self
    }

    @discardableResult
    func assert(expression: (Self) -> Bool) -> Self {
        XCTAssert(expression(self))
        return self
    }

    func eightDaysLater() -> Self {
        // close app
        XCUIDevice.shared.press(.home)

        // open app 8 days later
        // (test harness ensures that 8 days pass whenever we close the app)

        XCUIApplication().activate()
        usleep(500000) // wait for app opening animation
        return self
    }
}

class Page : PageChainable {
    let app: XCUIApplication

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func tapButton(_ label: String) -> Self {
        app.buttons[label].tap()
        return self
    }
}

class StatusPage : Page {
    var checkinQuestionnairePopup: CheckinQuestionnairePopup {
        CheckinQuestionnairePopup(app)
    }
}

class StatusOkPage : StatusPage {
    var hasStatusOkHeading: Bool {
        app.staticTexts["Follow the current advice to stop the spread of coronavirus"].exists
    }

    func tapFeelUnwell() -> SymptomsTemperaturePage {
        app.staticTexts["I feel unwell"].tap()
        return SymptomsTemperaturePage(app)
    }
}

class StatusSymptomaticPage : StatusPage {
    var hasStatusSymptomaticHeading: Bool {
        app.staticTexts["Your symptoms indicate you may have coronavirus. Please self-isolate and apply for a test."].exists
    }

    var hasBookNowAdvice: Bool {
        app.staticTexts["Please book a coronavirus test immediately. Write down your reference code and phone 0800 540 4900"].exists
    }
}

class SymptomsTemperaturePage : Page {
    func tapTemperatureOption() -> Self { return tapButton("Yes, I have a high temperature") }

    func tapNoTemperatureOption() -> Self { return tapButton("No, I do not have a high temperature") }

    func tapContinue() -> SymptomsCoughPage {
        tapButton("Continue")
        return SymptomsCoughPage(app)
    }
}

class SymptomsCoughPage : Page {
    func tapCoughOption() -> Self { return tapButton("Yes, I have a new continuous cough") }

    func tapNoCoughOption() -> Self { return tapButton("No, I do not have a new continuous cough") }

    func tapContinue() -> SymptomsAdvicePage {
        app.buttons["Continue"].tap()
        return SymptomsAdvicePage(app)
    }
}

class SymptomsAdvicePage : Page {
    var hasNoSymptoms: Bool {
        app.staticTexts["You do not appear to have coronavirus symptoms"].exists
    }

    func tapDone() -> StatusOkPage {
        tapButton("Done")
        return StatusOkPage(app)
    }

    func tapStartDateButton() -> Self { return tapButton("Select start date") }

    func tapContinue() -> SymptomsSubmitPage {
        app.buttons["Continue"].tap()
        return SymptomsSubmitPage(app)
    }
}

class SymptomsSubmitPage : Page {
    func tapAccurateConfirmationToggle() -> Self {
        app.switches["Please toggle the switch to confirm the information you entered is accurate"].tap()
        return self
    }

    func tapSubmit() -> StatusSymptomaticPage {
        tapButton("Submit")
        return StatusSymptomaticPage(app)
    }
}

class CheckinQuestionnairePopup : Page {
    var isShowingCheckinPrompt: Bool {
        app.staticTexts["How are you feeling today?"].exists
    }

    func tapUpdateSymptoms() -> CheckinTemperaturePage {
        tapButton("Update my symptoms")
        return CheckinTemperaturePage(app)
    }
}

class CheckinPage : Page {
    func tapCancel() -> CheckinQuestionnairePopup {
        tapButton("Cancel")
        return CheckinQuestionnairePopup(app)
    }
}

class CheckinTemperaturePage : CheckinPage {
    func tapTemperatureOption() -> Self { return tapButton("Yes, I have a high temperature") }

    func tapNoTemperatureOption() -> Self { return tapButton("No, I do not have a high temperature") }

    func tapContinue() -> CheckinCoughPage {
        tapButton("Continue")
        return CheckinCoughPage(app)
    }
}

class CheckinCoughPage : CheckinPage {
    func tapCoughOption() -> Self { return tapButton("Yes, I have a new continuous cough") }

    func tapNoCoughOption() -> Self { return tapButton("No, I do not have a new continuous cough") }

    func tapSubmit() -> CheckinAdvicePage {
        tapButton("Submit")
        return CheckinAdvicePage(app)
    }
}

class CheckinAdvicePage : CheckinPage {
    func expectNoAdvicePopup() -> StatusSymptomaticPage {
        return StatusSymptomaticPage(app)
    }

    func checkAndDismissCoughAdvice() -> StatusOkPage {
        XCTAssert(app.staticTexts["Although you still have a continuous cough, you can now follow the current advice."].exists)
        tapButton("Close")
        return StatusOkPage(app)
    }
}
