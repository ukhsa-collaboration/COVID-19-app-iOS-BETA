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

    func testNotRegistered() {
        // TODO
    }

    func testSubmitTapped() {
        let registration: Registration = Registration.fake
        let persistenceDouble = PersistenceDouble(registration: registration)

        let contactEvents = [ContactEvent(sonarId: UUID())]
        let eventRecorderDouble = TestContactEventRecorder(contactEvents)

        var actualRegistration: Registration?
        var actualContactEvents: [ContactEvent]?

        let vc = SubmitSymptomsViewController.instantiate()
        vc._inject(
            persistence: persistenceDouble,
            contactEventRecorder: eventRecorderDouble,
            sendContactEvents: { registration, contactEvents, _ in
                actualRegistration = registration
                actualContactEvents = contactEvents
            }
        )

        let unwinder = SelfDiagnosisUnwinder()
        parentViewControllerForTests.show(viewController: unwinder)
        unwinder.present(vc, animated: false)

        let button = PrimaryButton()
        vc.submitTapped(button)

        XCTAssertFalse(button.isEnabled)
        XCTAssertEqual(actualRegistration, registration)
        XCTAssertEqual(actualContactEvents, contactEvents)
    }

    func testSubmitSuccess() {
        let persistenceDouble = PersistenceDouble(registration: Registration.fake)
        let testContactEvent = ContactEvent(sonarId: UUID())
        let eventRecorderDouble = TestContactEventRecorder([testContactEvent])

        var completion: ((Result<Void, Error>) -> Void)?

        let vc = SubmitSymptomsViewController.instantiate()
        vc._inject(
            persistence: persistenceDouble,
            contactEventRecorder: eventRecorderDouble,
            sendContactEvents: { completion = $2 }
        )

        let unwinder = SelfDiagnosisUnwinder()
        parentViewControllerForTests.show(viewController: unwinder)
        unwinder.present(vc, animated: false)

        let button = PrimaryButton()
        vc.submitTapped(button)

        XCTAssertNotNil(completion)

        completion?(.success(()))
        
        XCTAssertTrue(eventRecorderDouble.hasReset)
        XCTAssertTrue(button.isEnabled)
        XCTAssertTrue(unwinder.didUnwindFromSelfDiagnosis)
    }

    func testSubmitFailure() {
        let persistenceDouble = PersistenceDouble(registration: Registration.fake)
        let eventRecorderDouble = TestContactEventRecorder()

        var completion: ((Result<Void, Error>) -> Void)?

        let vc = SubmitSymptomsViewController.instantiate()
        vc._inject(
            persistence: persistenceDouble,
            contactEventRecorder: eventRecorderDouble,
            sendContactEvents: { completion = $2 }
        )

        let unwinder = SelfDiagnosisUnwinder()
        parentViewControllerForTests.show(viewController: unwinder)
        unwinder.present(vc, animated: false)

        let button = PrimaryButton()
        vc.submitTapped(button)

        XCTAssertNotNil(completion)


        // TODO: Fill in with the expected behavior - this currently panics.
//        completion?(.failure(FakeError.fake))
//
//        XCTAssertTrue(button.isEnabled)
    }

}


class SelfDiagnosisUnwinder: UIViewController {
    var didUnwindFromSelfDiagnosis = false
    @IBAction func unwindFromSelfDiagnosis(unwindSegue: UIStoryboardSegue) {
        didUnwindFromSelfDiagnosis = true
    }
}
