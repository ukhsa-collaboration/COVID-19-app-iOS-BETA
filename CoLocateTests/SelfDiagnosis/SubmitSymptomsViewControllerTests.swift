//
//  SubmitSymptomsViewControllerTests.swift
//  CoLocateTests
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
            hasHighTemperature: true,
            hasNewCough: false,
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
        makeSubject(hasHighTemperature: false, hasNewCough: false)

        let unwinder = SelfDiagnosisUnwinder()
        parentViewControllerForTests.viewControllers = [unwinder]
        unwinder.present(vc, animated: false)

        vc.submitTapped(PrimaryButton())

        XCTAssertNil(persistence.selfDiagnosis)
        XCTAssertTrue(unwinder.didUnwindFromSelfDiagnosis)
        XCTAssertFalse(contactEventsUploader.uploadCalled)
    }

    func testPersistsDiagnosisAndSubmitsIfOnlyTemperature() {
        makeSubject(hasHighTemperature: true, hasNewCough: false, startDate: Date())

        vc.submitTapped(PrimaryButton())

        XCTAssertEqual(persistence.selfDiagnosis?.symptoms, [.temperature])
        XCTAssertTrue(contactEventsUploader.uploadCalled)
    }

    func testPersistsDiagnosisAndSubmitsIfOnlyCough() {
        makeSubject(hasHighTemperature: false, hasNewCough: true, startDate: Date())

        vc.submitTapped(PrimaryButton())

        XCTAssertEqual(persistence.selfDiagnosis?.symptoms, [.cough])
        XCTAssertTrue(contactEventsUploader.uploadCalled)
    }

    func testPersistsDiagnosisAndSubmitsIfBoth() {
        makeSubject(hasHighTemperature: true, hasNewCough: true, startDate: Date())

        vc.submitTapped(PrimaryButton())

        XCTAssertEqual(persistence.selfDiagnosis?.symptoms, [.temperature, .cough])
        XCTAssertTrue(contactEventsUploader.uploadCalled)
    }

    func testPersistsStartDate() {
        let date = Date()
        makeSubject(hasHighTemperature: true, hasNewCough: true, startDate: date)

        vc.submitTapped(PrimaryButton())

        XCTAssertEqual(persistence.selfDiagnosis?.startDate, date)
    }

    func testRequiresStartDate() {
        makeSubject(hasHighTemperature: true, hasNewCough: true)

        vc.submitTapped(PrimaryButton())

        XCTAssertNil(persistence.selfDiagnosis?.symptoms)
        XCTAssertFalse(contactEventsUploader.uploadCalled)
    }

    private func makeSubject(
        registration: Registration = Registration.fake,
        hasHighTemperature: Bool = false,
        hasNewCough: Bool = false,
        startDate: Date? = nil
    ) {
        persistence.registration = registration

        vc = SubmitSymptomsViewController.instantiate()
        vc.inject(
            persisting: persistence,
            contactEventsUploader: contactEventsUploader,
            hasHighTemperature: hasHighTemperature,
            hasNewCough: hasNewCough
        )
        XCTAssertNotNil(vc.view)

        if let date = startDate {
            vc.startDateViewController(vc.startDateViewController, didSelectDate: date)
        }
    }

}

fileprivate class SelfDiagnosisUnwinder: UIViewController {
    var didUnwindFromSelfDiagnosis = false
    @IBAction func unwindFromSelfDiagnosis(unwindSegue: UIStoryboardSegue) {
        didUnwindFromSelfDiagnosis = true
    }
}
