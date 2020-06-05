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
        XCTAssertTrue(submitSymptomsPage.accurateConfirmationToggle.exists)
        submitSymptomsPage.accurateConfirmationToggle.tap()
        submitSymptomsPage.submitButton.tap()
        
        let symptomaticPage = StatusSymptomaticPage(app)
        XCTAssertTrue(symptomaticPage.title.exists)


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
        XCTAssertTrue(checkinTemperaturePage.title.exists)
        checkinTemperaturePage.temperatureOption.tap()
        checkinTemperaturePage.continueButton.tap()
        
        let checkinCoughPage = CheckinCoughPage(app)
        XCTAssertTrue(checkinCoughPage.title.exists)
        checkinCoughPage.coughOption.tap()
        checkinCoughPage.continueButton.tap()
        
        let checkinAnosmiaPage = CheckinAnosmiaPage(app)
        XCTAssertTrue(checkinAnosmiaPage.title.exists)
        checkinAnosmiaPage.haveSymptomsOption.tap()
        checkinAnosmiaPage.continueButton.tap()
        
        let checkinSneezePage = CheckinSneezePage(app)
        XCTAssertTrue(checkinSneezePage.title.exists)
        checkinSneezePage.haveSymptomsOption.tap()
        checkinSneezePage.continueButton.tap()
        
        let checkinNauseaPage = CheckinNauseaPage(app)
        XCTAssertTrue(checkinNauseaPage.title.exists)
        checkinNauseaPage.haveSymptomsOption.tap()
        checkinNauseaPage.continueButton.tap()
        
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
        checkinCoughPage.continueButton.tap()
        
        XCTAssertTrue(checkinAnosmiaPage.title.exists)
        checkinAnosmiaPage.noSymptomsOption.tap()
        checkinAnosmiaPage.continueButton.tap()
        
        XCTAssertTrue(checkinSneezePage.title.exists)
        checkinSneezePage.haveSymptomsOption.tap()
        checkinSneezePage.continueButton.tap()
        
        XCTAssertTrue(checkinNauseaPage.title.exists)
        checkinNauseaPage.haveSymptomsOption.tap()
        checkinNauseaPage.continueButton.tap()
        
        
        // ...they are told to return to "current advice"...
        let checkinAdvicePage = CheckinAdvicePage(app)
        XCTAssertTrue(checkinAdvicePage.stillHaveSymptomsButDontIsolate.exists)
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
    
    func testScrollsAdviceIntoViewFromSelfDiagnosis() {
        let statusOkPage = StatusOkPage(app)
        // Swipe up until advice isn't visible (we assume 5 is more than enough)
        for _ in 0..<5 {
            app.swipeUp()
            if !statusOkPage.title.isHittable {
                break
            }
        }
        
        // There might not be enough content to warrant checking we scroll advice back into view
        if statusOkPage.title.isHittable { return }
        XCTAssertFalse(statusOkPage.title.isHittable)
        statusOkPage.feelUnwellButton.tap()
        
        let temperaturePage = SymptomsTemperaturePage(app)
        temperaturePage.temperatureOption.tap()
        temperaturePage.continueButton.tap()
        
        let coughPage = SymptomsCoughPage(app)
        coughPage.coughOption.tap()
        coughPage.continueButton.tap()
        
        let anosmiaPage = SymptomsAnosmiaPage(app)
        anosmiaPage.anosmiaOption.tap()
        anosmiaPage.continueButton.tap()
        
        let sneezePage = SymptomsSneezePage(app)
        sneezePage.haveSymptomsOption.tap()
        sneezePage.continueButton.tap()
        
        let nauseaPage = SymptomsNauseaPage(app)
        nauseaPage.haveSymptomsOption.tap()
        nauseaPage.continueButton.tap()
        
        let summaryPage = SymptomsSummaryPage(app)
        summaryPage.startDateButton.tap()
        summaryPage.continueButton.tap()
        
        let submitSymptomsPage = SymptomsSubmitPage(app)
        submitSymptomsPage.accurateConfirmationToggle.tap()
        submitSymptomsPage.submitButton.tap()
        
        let symptomaticPage = StatusSymptomaticPage(app)
        XCTAssertTrue(symptomaticPage.title.isHittable)
    }
    
    func testScrollsAdviceIntoViewFromCheckin() {
        let statusOkPage = StatusOkPage(app)
        statusOkPage.feelUnwellButton.tap()
        
        let temperaturePage = SymptomsTemperaturePage(app)
        temperaturePage.temperatureOption.tap()
        temperaturePage.continueButton.tap()
        
        let coughPage = SymptomsCoughPage(app)
        coughPage.coughOption.tap()
        coughPage.continueButton.tap()
        
        let anosmiaPage = SymptomsAnosmiaPage(app)
        anosmiaPage.anosmiaOption.tap()
        anosmiaPage.continueButton.tap()
        
        let sneezePage = SymptomsSneezePage(app)
        sneezePage.haveSymptomsOption.tap()
        sneezePage.continueButton.tap()
        
        let nauseaPage = SymptomsNauseaPage(app)
        nauseaPage.haveSymptomsOption.tap()
        nauseaPage.continueButton.tap()
        
        let summaryPage = SymptomsSummaryPage(app)
        summaryPage.startDateButton.tap()
        summaryPage.continueButton.tap()
        
        let submitSymptomsPage = SymptomsSubmitPage(app)
        submitSymptomsPage.accurateConfirmationToggle.tap()
        submitSymptomsPage.submitButton.tap()
        
        let symptomaticPage = StatusSymptomaticPage(app)
        
        // Swipe up until advice isn't visible (we assume 5 is more than enough)
        for _ in 0..<5 {
            app.swipeUp()
            if !symptomaticPage.title.isHittable {
               break
            }
        }
        
        // There might not be enough content to warrant checking we scroll advice back into view
        if symptomaticPage.title.isHittable { return }
        XCTAssertFalse(symptomaticPage.title.isHittable)

        eightDaysLater()
        let checkinPopup = CheckinQuestionnairePopup(app)
        checkinPopup.updateSymptomsButton.tap()
        
        let checkinTemperaturePage = CheckinTemperaturePage(app)
        checkinTemperaturePage.cancelButton.tap()
        
        checkinPopup.updateSymptomsButton.tap()
        checkinTemperaturePage.temperatureOption.tap()
        checkinTemperaturePage.continueButton.tap()
        
        let checkinCoughPage = CheckinCoughPage(app)
        checkinCoughPage.coughOption.tap()
        checkinCoughPage.continueButton.tap()
        
        let checkinAnosmiaPage = CheckinAnosmiaPage(app)
        checkinAnosmiaPage.haveSymptomsOption.tap()
        checkinAnosmiaPage.continueButton.tap()
        
        let checkinSneezePage = CheckinSneezePage(app)
        checkinSneezePage.haveSymptomsOption.tap()
        checkinSneezePage.continueButton.tap()
        
        let checkinNauseaPage = CheckinNauseaPage(app)
        checkinNauseaPage.haveSymptomsOption.tap()
        checkinNauseaPage.continueButton.tap()
        
        XCTAssertTrue(symptomaticPage.title.isHittable)
    }
}
