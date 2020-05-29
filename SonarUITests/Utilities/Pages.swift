//
//  Pages.swift
//  SonarUITests
//
//  Created by NHSX on 18/05/2020
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest

class Page {
    let app: XCUIApplication

    init(_ app: XCUIApplication) {
        self.app = app
    }
}

class StatusExposedPage : Page {
    var title: XCUIElement {
        app.staticTexts["You have been near someone who has coronavirus symptoms"]
    }
    
    var feelUnwellButton: XCUIElement {
        app.buttons.element(matching: NSPredicate(format: "label BEGINSWITH %@", "I feel unwell"))
    }
}

class StatusExposedSymptomaticPage : Page {
    var title: XCUIElement {
        app.staticTexts["Your symptoms indicate you may have coronavirus. Please isolate yourself and your household and book a test."]
    }
}


class StatusOkPage : Page {
    var title: XCUIElement {
        app.staticTexts["Follow the current advice to stop the spread of coronavirus"]
    }
    
    var feelUnwellButton: XCUIElement {
        app.buttons.element(matching: NSPredicate(format: "label BEGINSWITH %@", "I feel unwell"))
    }
}

class StatusSymptomaticPage : Page {
    var title: XCUIElement {
        app.staticTexts["Your symptoms indicate you may have coronavirus. Please isolate yourself and your household and book a test."]
    }
}

class PositiveTestStatusPage : Page {
    var hasPositiveTestHeading: Bool {
        app.staticTexts["Your test result indicates you have coronavirus. Please isolate yourself and your household."].exists
    }
    
    var drawerDismissButton: XCUIElement {
        app.buttons["Close"]
    }
}

class NegativeTestSymptomaticPage : Page {
    var noSymptomsButton: XCUIElement {
        app.buttons["I no longer have symptoms"]
    }
    
    var hasSymptomsButton: XCUIElement {
        app.buttons["Update my symptoms"]
    }
}

class SymptomsTemperaturePage : Page {
    var title: XCUIElement {
        app.staticTexts["Do you have a high temperature (fever)?"]
    }
    
    var temperatureOption: XCUIElement {
        app.buttons["Yes, I have a high temperature"]
    }
    
    var noTemperatureOption: XCUIElement {
        app.buttons["No, I do not have a high temperature"]
    }
    
    var continueButton: XCUIElement {
        app.buttons["Continue"]
    }
}

class SymptomsCoughPage : Page {
    var title: XCUIElement {
        app.staticTexts["Do you have a new continuous cough?"]
    }
    
    var coughOption: XCUIElement {
        app.buttons["Yes, I have a new continuous cough"]
    }

    var noCoughOption: XCUIElement {
        app.buttons["No, I do not have a new continuous cough"]
    }

    var continueButton: XCUIElement {
        app.buttons["Continue"]
    }
}

class SymptomsAnosmiaPage : Page {
    var title: XCUIElement {
        app.staticTexts["Have you had a loss or change to your sense of smell or taste?"]
    }
    
    var anosmiaOption: XCUIElement {
        app.buttons["Yes, I have a loss or change to my sense of smell or taste"]
    }
    
    var noAnosmiaOption: XCUIElement {
        app.buttons["No, I don’t have a loss or change to my sense of smell or taste"]
    }
    
    var continueButton: XCUIElement {
        app.buttons["Continue"]
    }
}

class SymptomsSneezePage : Page {
    var title: XCUIElement {
        app.staticTexts["Do you have a runny nose, feel feverish or suffer from sneezing?"]
    }
    
    var haveSymptomsOption: XCUIElement {
        app.buttons["Yes, I have at least one of these symptoms"]
    }
    
    var noSymptomsOption: XCUIElement {
        app.buttons["No, I do not have any of these symptoms"]
    }
    
    var continueButton: XCUIElement {
        app.buttons["Continue"]
    }
}

class SymptomsNauseaPage : Page {
    var title: XCUIElement {
        app.staticTexts["Do you have diarrhoea, nausea, vomiting or a loss of appetite?"]
    }
    
    var haveSymptomsOption: XCUIElement {
        app.buttons["Yes, I have at least one of these symptoms"]
    }
    
    var noSymptomsOption: XCUIElement {
        app.buttons["No, I do not have any of these symptoms"]
    }
    
    var continueButton: XCUIElement {
        app.buttons["Continue"]
    }
}

class SymptomsSummaryPage : Page {
    var sypmtomaticTitle: XCUIElement {
        app.staticTexts["Check your answers"]
    }
    
    var asypmtomaticTitle: XCUIElement {
        app.staticTexts["You do not appear to have coronavirus symptoms"]
    }
    
    var highTemperature: XCUIElement {
        app.staticTexts["I have a high temperature"]
    }
    
    var nausea: XCUIElement {
        app.staticTexts["I have at least one of these symptoms: diarrhoea, nausea, vomiting or loss of appetite"]
    }

    var doneButton: XCUIElement {
        app.buttons["Done"]
    }
    
    var startDateButton: XCUIElement {
        app.buttons["Select start date"]
    }

    var continueButton: XCUIElement {
        app.buttons["Continue"]
    }
}

class SymptomsSubmitPage : Page {
    var title: XCUIElement {
        app.staticTexts["Add my symptoms"]
    }
    
    var accurateConfirmationToggle: XCUIElement {
        app.switches["Please toggle the switch to confirm the information you entered is accurate"]
    }
    
    var submitButton: XCUIElement {
        app.buttons["Submit"]
    }
}

class CheckinQuestionnairePopup : Page {
    var title: XCUIElement {
        app.staticTexts["How are you feeling today?"]
    }
    
    var updateSymptomsButton: XCUIElement {
        app.buttons["Update my symptoms"]
    }
}

class CheckinTemperaturePage : Page {
    var title: XCUIElement {
        app.staticTexts["Do you still have a high temperature?"]
    }
    
    var cancelButton: XCUIElement {
        app.buttons["Cancel"]
    }
    
    var continueButton: XCUIElement {
        app.buttons["Continue"]
    }
    
    var temperatureOption: XCUIElement {
        app.buttons["Yes, I have a high temperature"]
    }

    var noTemperatureOption: XCUIElement {
        app.buttons["No, I do not have a high temperature"]
    }
}

class CheckinCoughPage : Page {
    var title: XCUIElement {
        app.staticTexts["Do you still have a continuous cough?"]
    }
    
    var coughOption: XCUIElement {
        app.buttons["Yes, I have a new continuous cough"]
    }
    
    var noCoughOption: XCUIElement {
        app.buttons["No, I do not have a new continuous cough"]
    }
    
    var continueButton: XCUIElement {
        app.buttons["Continue"]
    }
}

class CheckinAnosmiaPage: Page {
    var title: XCUIElement {
        app.staticTexts["Do you still have a loss or change to your sense of smell or taste?"]
    }
    
    var haveSymptomsOption: XCUIElement {
        app.buttons["Yes, I have a loss or change to my sense of smell or taste"]
    }
    
    var noSymptomsOption: XCUIElement {
        app.buttons["No, I don’t have a loss or change to my sense of smell or taste"]
    }
    
    var continueButton: XCUIElement {
        app.buttons["Continue"]
    }
}

class CheckinSneezePage: Page {
    var title: XCUIElement {
        app.staticTexts["Do you still have a runny nose, feel feverish or suffer from sneezing?"]
    }
    
    var haveSymptomsOption: XCUIElement {
        app.buttons["Yes, I have at least one of these symptoms"]
    }
    
    var noSymptomsOption: XCUIElement {
        app.buttons["No, I do not have any of these symptoms"]
    }
    
    var continueButton: XCUIElement {
        app.buttons["Continue"]
    }
}

class CheckinNauseaPage: Page {
    var title: XCUIElement {
        app.staticTexts["Do you still have diarrhoea, nausea, vomiting or a loss of appetite?"]
    }
    
    var haveSymptomsOption: XCUIElement {
        app.buttons["Yes, I have at least one of these symptoms"]
    }
    
    var noSymptomsOption: XCUIElement {
        app.buttons["No, I do not have any of these symptoms"]
    }
    
    var continueButton: XCUIElement {
        app.buttons["Continue"]
    }
}

class CheckinAdvicePage : Page {
    var stillHaveSymptomsButDontIsolate: XCUIElement {
        app.staticTexts["Although you still have some symptoms you can now stop self-isolating and follow the current advice for the general public."]
    }
    
    var closeButton: XCUIElement {
        app.buttons["Close"]
    }
}
