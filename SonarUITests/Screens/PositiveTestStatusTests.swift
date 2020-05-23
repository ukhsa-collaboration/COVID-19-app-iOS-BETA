//
//  PositiveTestStatusTests.swift
//  SonarUITests
//
//  Created by NHSX on 21/05/2020
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest

class PositiveTestStatusTests: ScreenTestCase {

    override var screen: Screen { .positiveTestStatus }

    func testPositiveTestResultFlow() {

        // Ensure the positive test status page has the correct heading
        let positiveTestStatusPage = PositiveTestStatusPage(app)
        XCTAssertTrue(positiveTestStatusPage.hasPositiveTestHeading)
        
        eightDaysLater()
        
        // Ensure the positive test status shows the checkin popup after 7 days
        let checkinPopup = CheckinQuestionnairePopup(app)
        XCTAssertTrue(checkinPopup.title.exists)
    }
}
