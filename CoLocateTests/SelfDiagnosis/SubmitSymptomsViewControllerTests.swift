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

    func testNotRegistered() throws {
        throw XCTSkip("TODO: write this test")
    }

    func testSubmitTapped() throws {
        let registration = Registration(id: UUID(uuidString: "FA817D5C-C615-4ABE-83B5-ABDEE8FAB8A6")!, secretKey: Data())
        let contactEvents = [ContactEvent(sonarId: UUID().data)]
        let session = SessionDouble()

        let vc = SubmitSymptomsViewController.instantiate()
        vc.inject(
            persistence:  PersistenceDouble(registration: registration),
            contactEventRepository: MockContactEventRepository(contactEvents: contactEvents),
            session: session,
            hasHighTemperature: false,
            hasNewCough: true
        )
        XCTAssertNotNil(vc.view)

        let button = PrimaryButton()
        vc.submitTapped(button)

        guard let request = session.requestSent as? PatchContactEventsRequest else {
            XCTFail("Expected a PatchContactEventsRequest but got \(String(describing: session.requestSent))")
            return
        }

        XCTAssertEqual(request.path, "/api/residents/FA817D5C-C615-4ABE-83B5-ABDEE8FAB8A6")

        switch request.method {
        case .patch(let data):
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode([String: [SonarIdUuid]].self, from: data)
            // Can't compare the entire contact events because the timestamp loses precision
            // when JSON encoded and decoded.
            XCTAssertEqual(decoded["contactEvents"]?.first?.sonarId, contactEvents.first?.sonarId.flatMap { UUID(data: $0) }?.uuidString)
        default:
            XCTFail("Expected a patch request but got \(request.method)")
        }
    }
    
    func testPreventsDoubleSubmission() {
        let registration = Registration(id: UUID(uuidString: "FA817D5C-C615-4ABE-83B5-ABDEE8FAB8A6")!, secretKey: Data())
        let session = SessionDouble()
        
        let vc = SubmitSymptomsViewController.instantiate()
        vc.inject(
            persistence:  PersistenceDouble(registration: registration),
            contactEventRepository: MockContactEventRepository(contactEvents: []),
            session: session,
            hasHighTemperature: false,
            hasNewCough: true
        )
        XCTAssertNotNil(vc.view)
        
        let button = PrimaryButton()
        vc.submitTapped(button)
        
        XCTAssertNotNil(session.requestSent)
        session.requestSent = nil
        vc.submitTapped(button)
        XCTAssertNil(session.requestSent)
    }
    
    func testHasNoSymptoms() {
        let registration: Registration = Registration.fake
        let persistenceDouble = PersistenceDouble(registration: registration)
        let sessionDouble = SessionDouble()

        let contactEventRepository = MockContactEventRepository(contactEvents: [ContactEvent(sonarId: Data())])

        let vc = SubmitSymptomsViewController.instantiate()
        XCTAssertNotNil(vc.view)
        vc.inject(
            persistence: persistenceDouble,
            contactEventRepository: contactEventRepository,
            session: sessionDouble,
            hasHighTemperature: false,
            hasNewCough: false
        )

        let unwinder = SelfDiagnosisUnwinder()
        parentViewControllerForTests.viewControllers = [unwinder]
        unwinder.present(vc, animated: false)

        vc.submitTapped(PrimaryButton())

        XCTAssertNil(persistenceDouble.selfDiagnosis)
        XCTAssertTrue(unwinder.didUnwindFromSelfDiagnosis)
        XCTAssertNil(sessionDouble.requestSent)
    }

    func testPersistsDiagnosisAndSubmitsIfOnlyTemperature() {
        let registration: Registration = Registration.fake
        let persistenceDouble = PersistenceDouble(registration: registration)
        let sessionDouble = SessionDouble()

        let contactEventRepository = MockContactEventRepository(contactEvents: [ContactEvent(sonarId: Data())])

        let vc = SubmitSymptomsViewController.instantiate()
        XCTAssertNotNil(vc.view)
        vc.inject(
            persistence: persistenceDouble,
            contactEventRepository: contactEventRepository,
            session: sessionDouble,
            hasHighTemperature: true,
            hasNewCough: false
        )

        vc.submitTapped(PrimaryButton())

        XCTAssertEqual(persistenceDouble.selfDiagnosis?.symptoms, [.temperature])
        XCTAssertNotNil(sessionDouble.requestSent)
    }

    func testPersistsDiagnosisAndSubmitsIfOnlyCough() {
        let registration: Registration = Registration.fake
        let persistenceDouble = PersistenceDouble(registration: registration)
        let sessionDouble = SessionDouble()

        let contactEventRepository = MockContactEventRepository(contactEvents: [ContactEvent(sonarId: Data())])
        
        let vc = SubmitSymptomsViewController.instantiate()
        XCTAssertNotNil(vc.view)
        vc.inject(
            persistence: persistenceDouble,
            contactEventRepository: contactEventRepository,
            session: sessionDouble,
            hasHighTemperature: false,
            hasNewCough: true
        )

        vc.submitTapped(PrimaryButton())

        XCTAssertEqual(persistenceDouble.selfDiagnosis?.symptoms, [.cough])
        XCTAssertNotNil(sessionDouble.requestSent)
    }

    func testPersistsDiagnosisAndSubmitsIfBoth() {
        let registration: Registration = Registration.fake
        let persistenceDouble = PersistenceDouble(registration: registration)
        let sessionDouble = SessionDouble()

        let contactEventRepository = MockContactEventRepository(contactEvents: [ContactEvent(sonarId: Data())])

        let vc = SubmitSymptomsViewController.instantiate()
        XCTAssertNotNil(vc.view)
        vc.inject(
            persistence: persistenceDouble,
            contactEventRepository: contactEventRepository,
            session: sessionDouble,
            hasHighTemperature: true,
            hasNewCough: true
        )

        vc.submitTapped(PrimaryButton())

        XCTAssertEqual(persistenceDouble.selfDiagnosis?.symptoms, [.temperature, .cough])
        XCTAssertNotNil(sessionDouble.requestSent)
    }

    func testSubmitSuccess() {
        let contactEventRepository = MockContactEventRepository(contactEvents: [ContactEvent(sonarId: Data())])
        let session = SessionDouble()

        let vc = SubmitSymptomsViewController.instantiate()
        vc.inject(
            persistence: PersistenceDouble(registration: Registration.fake),
            contactEventRepository: contactEventRepository,
            session: session,
            hasHighTemperature: false,
            hasNewCough: true
        )
        XCTAssertNotNil(vc.view)

        let unwinder = SelfDiagnosisUnwinder()
        parentViewControllerForTests.viewControllers = [unwinder]
        unwinder.present(vc, animated: false)

        let button = PrimaryButton()
        vc.submitTapped(button)
        
        guard let sessionCompletion = session.executeCompletion else {
            XCTFail("Request was not made")
            return
        }
        
        sessionCompletion(Result<(), Error>.success(()))

        XCTAssertTrue(contactEventRepository.hasReset)
        XCTAssertTrue(unwinder.didUnwindFromSelfDiagnosis)
    }

    func testSubmitFailure() {
        let contactEventRepository = MockContactEventRepository(contactEvents: [ContactEvent(sonarId: Data())])
        let session = SessionDouble()

        let vc = SubmitSymptomsViewController.instantiate()
        parentViewControllerForTests.viewControllers = [vc]
        vc.inject(
            persistence: PersistenceDouble(registration: Registration.fake),
            contactEventRepository: contactEventRepository,
            session: session,
            hasHighTemperature: false,
            hasNewCough: true
        )
        XCTAssertNotNil(vc.view)

        let unwinder = SelfDiagnosisUnwinder()
        parentViewControllerForTests.viewControllers = [unwinder]
        unwinder.present(vc, animated: false)

        let button = PrimaryButton()
        vc.submitTapped(button)
        
        guard let sessionCompletion = session.executeCompletion else {
            XCTFail("Request was not made")
            return
        }
        
        sessionCompletion(Result<(), Error>.failure(ErrorForTest()))
        
        let expectation = XCTestExpectation(description: "Alert was presented")
        var done = false
        
        func pollPresentedVC() {
            if vc.presentedViewController as? UIAlertController != nil {
                expectation.fulfill()
            } else if !done {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: { pollPresentedVC() })
            }
        }
        
        pollPresentedVC()
        wait(for: [expectation], timeout: 2.0)
        done = true
    }

}


fileprivate class SelfDiagnosisUnwinder: UIViewController {
    var didUnwindFromSelfDiagnosis = false
    @IBAction func unwindFromSelfDiagnosis(unwindSegue: UIStoryboardSegue) {
        didUnwindFromSelfDiagnosis = true
    }
}

fileprivate class MockContactEventRepository: ContactEventRepository {
    
    var contactEvents: [ContactEvent] = []
    var hasReset: Bool = false
    
    init(contactEvents: [ContactEvent]) {
        self.contactEvents = contactEvents
    }
    
    func reset() {
        hasReset = true
    }
    
    func removeExpiredContactEvents() {
        
    }
}
