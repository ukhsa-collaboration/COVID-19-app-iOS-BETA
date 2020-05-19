//
//  Pages.swift
//  SonarUITests
//
//  Created by NHSX on 18/05/2020
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest

protocol PageChainable { }

extension PageChainable {
    @discardableResult
    func then(block: (Self) -> Void) -> Self {
        block(self)
        return self
    }

    @discardableResult
    func assert(file: StaticString = #file, line: UInt = #line, expression: (Self) -> Bool) -> Self {
        XCTAssert(expression(self), file: file, line: line)
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
        app.buttons.element(matching: NSPredicate(format: "label BEGINSWITH %@", "I feel unwell")).tap()
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

    func tapContinue() -> SymptomsSmellPage {
        app.buttons["Continue"].tap()
        return SymptomsSmellPage(app)
    }
}

class SymptomsSmellPage : Page {
    func tapSmellLossOption() -> Self { return tapButton("Yes, I have lost my sense of smell") }

    func tapNoSmellLossOption() -> Self { return tapButton("No, I have not lost my sense of smell") }

    func tapContinue() -> SymptomsFeverPage {
        app.buttons["Continue"].tap()
        return SymptomsFeverPage(app)
    }
}

class SymptomsFeverPage : Page {
    func tapHaveSymptomsOption() -> Self { return tapButton("Yes, I have at least one of these symptoms") }

    func tapNoSymptomsOption() -> Self { return tapButton("No, I do not have any of these symptoms") }

    func tapContinue() -> SymptomsNauseaPage {
        app.buttons["Continue"].tap()
        return SymptomsNauseaPage(app)
    }
}

class SymptomsNauseaPage : Page {
    func tapHaveSymptomsOption() -> Self { return tapButton("Yes, I have at least one of these symptoms") }

    func tapNoSymptomsOption() -> Self { return tapButton("No, I do not have any of these symptoms") }

    func tapContinue() -> SymptomsAdvicePage {
        app.buttons["Continue"].tap()
        return SymptomsAdvicePage(app)
    }
}

class SymptomsAdvicePage : Page {
    var hasNoSymptoms: Bool {
        app.staticTexts["You do not appear to have coronavirus symptoms"].exists
    }
    
    var hasHighTemperature: Bool {
        app.staticTexts["I have a high temperature"].exists
    }
    
    var hasNausea: Bool {
        app.staticTexts["I have at least one of these symptoms: diarrhoea, nausea, vomiting or loss of appetite"].exists
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
