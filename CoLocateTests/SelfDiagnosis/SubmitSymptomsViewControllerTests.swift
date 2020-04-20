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
    fileprivate var contactEventRepository: MockContactEventRepository!
    var session: SessionDouble!

    override func setUp() {
        super.setUp()

        persistence = PersistenceDouble()
        contactEventRepository = MockContactEventRepository()
        session = SessionDouble()
    }

    func testNotRegistered() throws {
        throw XCTSkip("TODO: write this test")
    }

    func testSubmitTapped() throws {
        let contactEvent = ContactEvent(sonarId: UUID().data)

        makeSubject(
            registration: Registration(id: UUID(uuidString: "FA817D5C-C615-4ABE-83B5-ABDEE8FAB8A6")!, secretKey: Data(), broadcastRotationKey: knownGoodECPublicKey()),
            contactEvents: [contactEvent],
            hasHighTemperature: true,
            hasNewCough: false,
            startDate: Date()
        )

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
            XCTAssertEqual(decoded["contactEvents"]?.first?.sonarId, contactEvent.sonarId.flatMap { UUID(data: $0) }?.uuidString)
        default:
            XCTFail("Expected a patch request but got \(request.method)")
        }
    }
    
    func testPreventsDoubleSubmission() {
        makeSubject(
            hasHighTemperature: true,
            hasNewCough: false,
            startDate: Date()
        )

        let button = PrimaryButton()
        vc.submitTapped(button)
        
        XCTAssertNotNil(session.requestSent)
        session.requestSent = nil
        vc.submitTapped(button)
        XCTAssertNil(session.requestSent)
    }
    
    func testHasNoSymptoms() {
        makeSubject(hasHighTemperature: false, hasNewCough: false)

        let unwinder = SelfDiagnosisUnwinder()
        parentViewControllerForTests.viewControllers = [unwinder]
        unwinder.present(vc, animated: false)

        vc.submitTapped(PrimaryButton())

        XCTAssertNil(persistence.selfDiagnosis)
        XCTAssertTrue(unwinder.didUnwindFromSelfDiagnosis)
        XCTAssertNil(session.requestSent)
    }

    func testPersistsDiagnosisAndSubmitsIfOnlyTemperature() {
        makeSubject(hasHighTemperature: true, hasNewCough: false, startDate: Date())

        vc.submitTapped(PrimaryButton())

        XCTAssertEqual(persistence.selfDiagnosis?.symptoms, [.temperature])
        XCTAssertNotNil(session.requestSent)
    }

    func testPersistsDiagnosisAndSubmitsIfOnlyCough() {
        makeSubject(hasHighTemperature: false, hasNewCough: true, startDate: Date())

        vc.submitTapped(PrimaryButton())

        XCTAssertEqual(persistence.selfDiagnosis?.symptoms, [.cough])
        XCTAssertNotNil(session.requestSent)
    }

    func testPersistsDiagnosisAndSubmitsIfBoth() {
        makeSubject(hasHighTemperature: true, hasNewCough: true, startDate: Date())

        vc.submitTapped(PrimaryButton())

        XCTAssertEqual(persistence.selfDiagnosis?.symptoms, [.temperature, .cough])
        XCTAssertNotNil(session.requestSent)
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
        XCTAssertNil(session.requestSent)
    }

    func testSubmitSuccess() {
        makeSubject(hasHighTemperature: false, hasNewCough: true, startDate: Date())

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
        makeSubject(hasHighTemperature: false, hasNewCough: true, startDate: Date())

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

        XCTAssertFalse(vc.submitErrorView.isHidden)
    }

    private func makeSubject(
        registration: Registration = Registration.fake,
        contactEvents: [ContactEvent] = [],
        hasHighTemperature: Bool = false,
        hasNewCough: Bool = false,
        startDate: Date? = nil
    ) {
        persistence.registration = registration
        contactEventRepository.contactEvents = contactEvents

        vc = SubmitSymptomsViewController.instantiate()
        vc.inject(
            persisting: persistence,
            contactEventRepository: contactEventRepository,
            session: session,
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

fileprivate class MockContactEventRepository: ContactEventRepository {
    
    var contactEvents: [ContactEvent] = []
    var hasReset: Bool = false
    
    init(contactEvents: [ContactEvent] = []) {
        self.contactEvents = contactEvents
    }
    
    func reset() {
        hasReset = true
    }
    
    func removeExpiredContactEvents(ttl: Double) {
        
    }
}
