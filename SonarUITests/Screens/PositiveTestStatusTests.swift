//
//  PositiveTestStatusTests.swift
//  SonarUITests
//
//  Created by NHSX on 21/05/2020
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

class PositiveTestStatusTests: ScreenTestCase {

    override var screen: Screen { .positiveTestStatus }

    func testPositiveTestResultFlow() {

        PositiveTestStatusPage(app)
            .assert { $0.hasPositiveTestHeading }
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
}
