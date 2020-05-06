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
        makeSubject(
            registration: Registration.fake,
            symptoms: [.temperature],
            startDate: Date()
        )

        let unwinder = SelfDiagnosisUnwinder()
        parentViewControllerForTests.viewControllers = [unwinder]
        unwinder.present(vc, animated: false)
        XCTAssertTrue(vc.errorLabel.isHidden)
        XCTAssertFalse(vc.confirmSwitch.isOn)
        
        let button = PrimaryButton()
        vc.submitTapped(button)

        XCTAssertFalse(contactEventsUploader.uploadCalled)
        XCTAssertFalse(vc.errorLabel.isHidden)
        XCTAssertEqual(vc.confirmSwitch.layer.borderColor, UIColor(named: "NHS Error")!.cgColor)
    }

    func testSubmitTappedWithConfirmationSwitchOn() throws {
        makeSubject(
            registration: Registration(id: UUID(uuidString: "FA817D5C-C615-4ABE-83B5-ABDEE8FAB8A6")!, secretKey: Data(), broadcastRotationKey: SecKey.sampleEllipticCurveKey),
            symptoms: [.temperature],
            startDate: Date()
        )

        let unwinder = SelfDiagnosisUnwinder()
        parentViewControllerForTests.viewControllers = [unwinder]
        unwinder.present(vc, animated: false)

        vc.confirmSwitch.isOn = true
        let button = PrimaryButton()
        vc.submitTapped(button)

        XCTAssertTrue(contactEventsUploader.uploadCalled)
        XCTAssertTrue(vc.errorLabel.isHidden)
    }
    
    func testHasNoSymptoms() {
        makeSubject(symptoms: [])

        let unwinder = SelfDiagnosisUnwinder()
        parentViewControllerForTests.viewControllers = [unwinder]
        unwinder.present(vc, animated: false)

        vc.submitTapped(PrimaryButton())

        XCTAssertNil(persistence.selfDiagnosis)
        XCTAssertFalse(contactEventsUploader.uploadCalled)
    }

    func testPersistsDiagnosisAndSubmitsIfOnlyTemperature() {
        makeSubject(symptoms: [.temperature])

        vc.confirmSwitch.isOn = true
        vc.submitTapped(PrimaryButton())

        XCTAssertEqual(persistence.selfDiagnosis?.symptoms, [.temperature])
        XCTAssertTrue(contactEventsUploader.uploadCalled)
    }

    func testPersistsDiagnosisAndSubmitsIfOnlyCough() {
        makeSubject(symptoms: [.cough])

        vc.confirmSwitch.isOn = true
        vc.submitTapped(PrimaryButton())

        XCTAssertEqual(persistence.selfDiagnosis?.symptoms, [.cough])
        XCTAssertTrue(contactEventsUploader.uploadCalled)
    }

    func testPersistsDiagnosisAndSubmitsIfBoth() {
        makeSubject(symptoms: [.temperature, .cough])

        vc.confirmSwitch.isOn = true
        vc.submitTapped(PrimaryButton())

        XCTAssertEqual(persistence.selfDiagnosis?.symptoms, [.temperature, .cough])
        XCTAssertTrue(contactEventsUploader.uploadCalled)
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
