//
//  NegativeTestStatusTests.swift
//  SonarUITests
//
//  Created by NHSX on 27/05/2020
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest

class NegativeTestStatusTests: ScreenTestCase {

    override var screen: Screen { .negativeTestSymptomatic }

    func testNoSymptomsOnOverlay() {
        // Check the correct overlay is shown
        let negativeTestStatusPage = NegativeTestSymptomaticPage(app)
        negativeTestStatusPage.noSymptomsButton.tap()

        // Check slecting no symptoms option returns to OK page
        let statusOKPage = StatusOkPage(app)
        XCTAssertTrue(statusOKPage.title.exists)
    }

    func testHasSymptomsOnOverlayStillHasTemperature() {
        // Check the correct overlay is shown
        let negativeTestStatusPage = NegativeTestSymptomaticPage(app)
        negativeTestStatusPage.hasSymptomsButton.tap()

        // User indicates they still have a temperature
        let checkinTemperaturePage = CheckinTemperaturePage(app)
        checkinTemperaturePage.temperatureOption.tap()
        checkinTemperaturePage.continueButton.tap()

        let checkinCoughPage = CheckinCoughPage(app)
        checkinCoughPage.coughOption.tap()
        checkinCoughPage.continueButton.tap()

        let checkinAnosmiaPage = CheckinAnosmiaPage(app)
        checkinAnosmiaPage.haveSymptomsOption.tap()
        checkinAnosmiaPage.continueButton.tap()

        // Ensure we navigate back to a symptomatic state if the user still has a temperature
        let symptomaticPage = StatusSymptomaticPage(app)
        XCTAssertTrue(symptomaticPage.title.exists)
    }

    func testHasSymptomsOnOverlayNoTemperature() {
        // Check the correct overlay is shown
        let negativeTestStatusPage = NegativeTestSymptomaticPage(app)
        negativeTestStatusPage.hasSymptomsButton.tap()

        // User indicates they still have a temperature
        let checkinTemperaturePage = CheckinTemperaturePage(app)
        checkinTemperaturePage.noTemperatureOption.tap()
        checkinTemperaturePage.continueButton.tap()

        let checkinCoughPage = CheckinCoughPage(app)
        checkinCoughPage.coughOption.tap()
        checkinCoughPage.continueButton.tap()

        let checkinAnosmiaPage = CheckinAnosmiaPage(app)
        checkinAnosmiaPage.haveSymptomsOption.tap()
        checkinAnosmiaPage.continueButton.tap()

        let checkinAdvicePage = CheckinAdvicePage(app)
        XCTAssertTrue(checkinAdvicePage.stillHaveSymptomsButDontIsolate.exists)
        checkinAdvicePage.closeButton.tap()

        // Ensure we navigate back to an 'ok' state if the user does not have a temperature
        let statusOKPage = StatusOkPage(app)
        XCTAssertTrue(statusOKPage.title.exists)
    }

}
