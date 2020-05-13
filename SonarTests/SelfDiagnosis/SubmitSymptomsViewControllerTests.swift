//
//  SubmitSymptomsViewControllerTests.swift
//  SonarTests
//
//  Created by NHSX on 4/8/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class SubmitSymptomsViewControllerTests: TestCase {

    var vc: SubmitSymptomsViewController!
    var persistence: PersistenceDouble!
    var contactEventsUploader: ContactEventsUploaderDouble!
    var schedulerDouble: SchedulerDouble!

    override func setUp() {
        super.setUp()

        persistence = PersistenceDouble()
        contactEventsUploader = ContactEventsUploaderDouble()
        schedulerDouble = SchedulerDouble()
    }
    
    func testSubmitTappedWithConfirmationSwitchOff() throws {
        let startDate = Date()
        makeSubject(
            registration: Registration.fake,
            symptoms: [.temperature],
            startDate: startDate
        )

        let unwinder = SelfDiagnosisUnwinder()
        parentViewControllerForTests.viewControllers = [unwinder]
        unwinder.present(vc, animated: false)
        XCTAssertTrue(vc.errorLabel.isHidden)
        XCTAssertFalse(vc.confirmSwitch.isOn)
        
        let button = PrimaryButton()
        vc.submitTapped(button)

        XCTAssertNil(contactEventsUploader.uploadStartDate)
        XCTAssertFalse(vc.errorLabel.isHidden)
        XCTAssertEqual(vc.confirmSwitch.layer.borderColor, UIColor(named: "NHS Error")!.cgColor)
    }

    func testSubmitTappedWithConfirmationSwitchOn() throws {
        let startDate = Date()
        makeSubject(
            registration: Registration(sonarId: UUID(uuidString: "FA817D5C-C615-4ABE-83B5-ABDEE8FAB8A6")!, secretKey: SecKey.sampleHMACKey, broadcastRotationKey: SecKey.sampleEllipticCurveKey),
            symptoms: [.temperature],
            startDate: startDate
        )

        let unwinder = SelfDiagnosisUnwinder()
        parentViewControllerForTests.viewControllers = [unwinder]
        unwinder.present(vc, animated: false)

        vc.confirmSwitch.isOn = true
        let button = PrimaryButton()
        vc.submitTapped(button)

        XCTAssertEqual(contactEventsUploader.uploadStartDate, startDate)
        XCTAssertTrue(vc.errorLabel.isHidden)
    }
    
    func testHasNoSymptoms() {
        makeSubject(symptoms: [])

        let unwinder = SelfDiagnosisUnwinder()
        parentViewControllerForTests.viewControllers = [unwinder]
        unwinder.present(vc, animated: false)

        vc.submitTapped(PrimaryButton())

        XCTAssertNil(persistence.selfDiagnosis)
        XCTAssertNil(contactEventsUploader.uploadStartDate)
    }

    func testPersistsDiagnosisAndSubmitsIfOnlyTemperature() {
        let startDate = Date()
        makeSubject(symptoms: [.temperature], startDate: startDate)

        vc.confirmSwitch.isOn = true
        vc.submitTapped(PrimaryButton())

        XCTAssertEqual(persistence.selfDiagnosis?.symptoms, [.temperature])
        XCTAssertEqual(contactEventsUploader.uploadStartDate, startDate)
    }

    func testPersistsDiagnosisAndSubmitsIfOnlyCough() {
        let startDate = Date()
        makeSubject(symptoms: [.cough], startDate: startDate)

        vc.confirmSwitch.isOn = true
        vc.submitTapped(PrimaryButton())

        XCTAssertEqual(persistence.selfDiagnosis?.symptoms, [.cough])
        XCTAssertEqual(contactEventsUploader.uploadStartDate, startDate)
    }

    func testPersistsDiagnosisAndSubmitsIfBoth() {
        let startDate = Date()
        makeSubject(symptoms: [.temperature, .cough], startDate: startDate)

        vc.confirmSwitch.isOn = true
        vc.submitTapped(PrimaryButton())

        XCTAssertEqual(persistence.selfDiagnosis?.symptoms, [.temperature, .cough])
        XCTAssertEqual(contactEventsUploader.uploadStartDate, startDate)
    }

    func testPersistsStartDate() {
        let date = Date()
        makeSubject(symptoms: [.temperature], startDate: date)

        vc.confirmSwitch.isOn = true
        vc.submitTapped(PrimaryButton())

        XCTAssertEqual(persistence.selfDiagnosis?.startDate, date)
    }

    private func makeSubject(
        registration: Registration = Registration.fake,
        symptoms: Set<Symptom> = [],
        startDate: Date = Date()
    ) {
        persistence.registration = registration

        vc = SubmitSymptomsViewController.instantiate()
        vc.inject(
            persisting: persistence,
            contactEventsUploader: contactEventsUploader,
            symptoms: symptoms,
            startDate: startDate,
            statusViewController: nil,
            localNotificationScheduler: schedulerDouble
        )
        XCTAssertNotNil(vc.view)
    }

}

fileprivate class SelfDiagnosisUnwinder: UIViewController {
    var didUnwindFromSelfDiagnosis = false
    @IBAction func unwindFromSelfDiagnosis(unwindSegue: UIStoryboardSegue) {
        didUnwindFromSelfDiagnosis = true
    }
}
