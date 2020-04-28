//
//  SubmitSymptomsViewControllerTests.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class SubmitSymptomsViewControllerTests: TestCase {

    var vc: SubmitSymptomsViewController!
    var persistence: PersistenceDouble!
    var contactEventsUploader: ContactEventsUploaderDouble!

    override func setUp() {
        super.setUp()

        persistence = PersistenceDouble()
        contactEventsUploader = ContactEventsUploaderDouble()
    }

    func testSubmitTapped() throws {
        makeSubject(
            registration: Registration(id: UUID(uuidString: "FA817D5C-C615-4ABE-83B5-ABDEE8FAB8A6")!, secretKey: Data(), broadcastRotationKey: knownGoodECPublicKey()),
            symptoms: [.temperature],
            startDate: Date()
        )

        let unwinder = SelfDiagnosisUnwinder()
        parentViewControllerForTests.viewControllers = [unwinder]
        unwinder.present(vc, animated: false)

        let button = PrimaryButton()
        vc.submitTapped(button)

        XCTAssertTrue(contactEventsUploader.uploadCalled)
        XCTAssertTrue(unwinder.didUnwindFromSelfDiagnosis)
    }
    
    func testHasNoSymptoms() {
        makeSubject(symptoms: [])

        let unwinder = SelfDiagnosisUnwinder()
        parentViewControllerForTests.viewControllers = [unwinder]
        unwinder.present(vc, animated: false)

        vc.submitTapped(PrimaryButton())

        XCTAssertNil(persistence.selfDiagnosis)
        XCTAssertTrue(unwinder.didUnwindFromSelfDiagnosis)
        XCTAssertFalse(contactEventsUploader.uploadCalled)
    }

    func testPersistsDiagnosisAndSubmitsIfOnlyTemperature() {
        makeSubject(symptoms: [.temperature])

        vc.submitTapped(PrimaryButton())

        XCTAssertEqual(persistence.selfDiagnosis?.symptoms, [.temperature])
        XCTAssertTrue(contactEventsUploader.uploadCalled)
    }

    func testPersistsDiagnosisAndSubmitsIfOnlyCough() {
        makeSubject(symptoms: [.cough])

        vc.submitTapped(PrimaryButton())

        XCTAssertEqual(persistence.selfDiagnosis?.symptoms, [.cough])
        XCTAssertTrue(contactEventsUploader.uploadCalled)
    }

    func testPersistsDiagnosisAndSubmitsIfBoth() {
        makeSubject(symptoms: [.temperature, .cough])

        vc.submitTapped(PrimaryButton())

        XCTAssertEqual(persistence.selfDiagnosis?.symptoms, [.temperature, .cough])
        XCTAssertTrue(contactEventsUploader.uploadCalled)
    }

    func testPersistsStartDate() {
        let date = Date()
        makeSubject(symptoms: [.temperature], startDate: date)

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
            startDate: startDate
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
