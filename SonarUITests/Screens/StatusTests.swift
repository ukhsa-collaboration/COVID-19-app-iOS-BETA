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

            // and are not immediately told to check in again
            .assert { !$0.checkinQuestionnairePopup.isShowingCheckinPrompt }

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

            // and are not immediately told to check in again
            .assert { !$0.checkinQuestionnairePopup.isShowingCheckinPrompt }

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
