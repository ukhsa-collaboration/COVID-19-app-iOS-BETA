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
        let statusOkPage = StatusOkPage(app)
        XCTAssertTrue(statusOkPage.title.exists)
        statusOkPage.feelUnwellButton.tap()
        
        let temperaturePage = SymptomsTemperaturePage(app)
        XCTAssertTrue(temperaturePage.title.exists)
        temperaturePage.temperatureOption.tap()
        temperaturePage.continueButton.tap()
        
        let coughPage = SymptomsCoughPage(app)
        XCTAssertTrue(coughPage.title.exists)
        coughPage.coughOption.tap()
        coughPage.continueButton.tap()
        
        let anosmiaPage = SymptomsAnosmiaPage(app)
        XCTAssertTrue(anosmiaPage.title.exists)
        anosmiaPage.anosmiaOption.tap()
        anosmiaPage.continueButton.tap()
        
        let sneezePage = SymptomsSneezePage(app)
        XCTAssertTrue(sneezePage.title.exists)
        sneezePage.haveSymptomsOption.tap()
        sneezePage.continueButton.tap()
        
        let nauseaPage = SymptomsNauseaPage(app)
        XCTAssertTrue(nauseaPage.title.exists)
        nauseaPage.haveSymptomsOption.tap()
        nauseaPage.continueButton.tap()
        
        let summaryPage = SymptomsSummaryPage(app)
        XCTAssertTrue(summaryPage.sypmtomaticTitle.exists)
        XCTAssertTrue(summaryPage.highTemperature.exists)
        summaryPage.startDateButton.tap()
        summaryPage.continueButton.tap()
        
        let submitSymptomsPage = SymptomsSubmitPage(app)
        XCTAssertTrue(submitSymptomsPage.title.exists)
        submitSymptomsPage.accurateConfirmationToggle.tap()
        submitSymptomsPage.submitButton.tap()
        
        
        let symptomaticPage = StatusSymptomaticPage(app)
        XCTAssertTrue(symptomaticPage.title.exists)
        XCTAssertTrue(symptomaticPage.bookNowAdvice.exists)
        
        
        eightDaysLater()
        let checkinPopup = CheckinQuestionnairePopup(app)
        XCTAssertTrue(checkinPopup.title.exists)
        checkinPopup.updateSymptomsButton.tap()
        
        // questionnaire reappears if the user cancels
        let checkinTemperaturePage = CheckinTemperaturePage(app)
        XCTAssertTrue(checkinTemperaturePage.title.exists)
        checkinTemperaturePage.cancelButton.tap()
        
        // if the user still has symptoms...
        XCTAssertTrue(checkinPopup.title.exists)
        checkinPopup.updateSymptomsButton.tap()
        checkinTemperaturePage.temperatureOption.tap()
        checkinTemperaturePage.continueButton.tap()
        let checkinCoughPage = CheckinCoughPage(app)
        checkinCoughPage.coughOption.tap()
        checkinCoughPage.submitButton.tap()

        // they are told to continue isolating
        XCTAssertTrue(symptomaticPage.title.exists)
        
        // and are not immediately told to check in again
        XCTAssertFalse(checkinPopup.title.exists)
        
        
        eightDaysLater()
        XCTAssertTrue(checkinPopup.title.exists)
        checkinPopup.updateSymptomsButton.tap()
        
        // if the user only has a cough...
        XCTAssertTrue(checkinTemperaturePage.title.exists)
        checkinTemperaturePage.noTemperatureOption.tap()
        checkinTemperaturePage.continueButton.tap()
        XCTAssertTrue(checkinCoughPage.title.exists)
        checkinCoughPage.coughOption.tap()
        checkinCoughPage.submitButton.tap()
        
        // ...they are told to return to "current advice"...
        let checkinAdvicePage = CheckinAdvicePage(app)
        XCTAssertTrue(checkinAdvicePage.stillHaveCough.exists)
        checkinAdvicePage.closeButton.tap()
        XCTAssertTrue(statusOkPage.title.exists)

        // and are not immediately told to check in again
        XCTAssertFalse(checkinPopup.title.exists)
    }

    func testSelfDiagnosisNegativeFlow() {
        let statusOkPage = StatusOkPage(app)
        XCTAssertTrue(statusOkPage.title.exists)
        statusOkPage.feelUnwellButton.tap()
        
        let temperaturePage = SymptomsTemperaturePage(app)
        XCTAssertTrue(temperaturePage.title.exists)
        temperaturePage.noTemperatureOption.tap()
        temperaturePage.continueButton.tap()
        
        let coughPage = SymptomsCoughPage(app)
        XCTAssertTrue(coughPage.title.exists)
        coughPage.noCoughOption.tap()
        coughPage.continueButton.tap()
        
        let anosmiaPage = SymptomsAnosmiaPage(app)
        XCTAssertTrue(anosmiaPage.title.exists)
        anosmiaPage.noAnosmiaOption.tap()
        anosmiaPage.continueButton.tap()
        
        let sneezePage = SymptomsSneezePage(app)
        XCTAssertTrue(sneezePage.title.exists)
        sneezePage.noSymptomsOption.tap()
        sneezePage.continueButton.tap()
        
        let nauseaPage = SymptomsNauseaPage(app)
        XCTAssertTrue(nauseaPage.title.exists)
        nauseaPage.noSymptomsOption.tap()
        nauseaPage.continueButton.tap()
        
        let summaryPage = SymptomsSummaryPage(app)
        XCTAssertTrue(summaryPage.asypmtomaticTitle.exists)
        summaryPage.doneButton.tap()
        
        XCTAssertTrue(statusOkPage.title.exists)
    }
}
