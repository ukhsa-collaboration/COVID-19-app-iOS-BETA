//
//  ExposureTests.swift
//  SonarUITests
//
//  Created by NHSX on 29/05/2020
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest

class ExposureTests: ScreenTestCase {
    override var screen: Screen { .exposedStatus }
    
    func testExposureNegativeFlow() {
        let statusExposedPage = StatusExposedPage(app)
        XCTAssertTrue(statusExposedPage.title.exists)
        statusExposedPage.feelUnwellButton.tap()
        
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
        
        XCTAssertTrue(statusExposedPage.title.exists)
    }
    
    func testExposurePositiveFlow() {
        let statusExposedPage = StatusExposedPage(app)
        XCTAssertTrue(statusExposedPage.title.exists)
        statusExposedPage.feelUnwellButton.tap()
        
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
        XCTAssertTrue(submitSymptomsPage.accurateConfirmationToggle.exists)
        submitSymptomsPage.accurateConfirmationToggle.tap()
        submitSymptomsPage.submitButton.tap()
        
        let statusExposedSymptomaticPage = StatusExposedSymptomaticPage(app)
        XCTAssertTrue(statusExposedSymptomaticPage.title.exists)
        
        eightDaysLater()
        
        // Not enough time has passed yet (needs to be > 14 days)
        let checkinPopup = CheckinQuestionnairePopup(app)
        XCTAssertFalse(checkinPopup.title.exists)

        eightDaysLater()
        
        // 16 days have passed, which is greater than the 14 days exposure duration
        XCTAssertTrue(checkinPopup.title.exists)
    }
}
