//
//  StatusViewControllerTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class StatusViewControllerTests: XCTestCase {

    func testStatusPermutations() {
        let permutations: [(Set<Symptom>, Bool, StatusViewController.Status)] = [
            ([], false, .initial),
            ([], true, .amber),
            ([.cough], false, .red),
            ([.cough], true, .red),
        ]

        for (symptoms, potentiallyExposed, expectedStatus) in permutations {
            let diagnosis = SelfDiagnosis(symptoms: symptoms, startDate: Date())
            let persistence = PersistenceDouble(potentiallyExposed: potentiallyExposed, diagnosis: diagnosis)
            let vc = makeViewController(persistence: persistence)
            vc.viewWillAppear(false)

            XCTAssertEqual(vc.status, expectedStatus)
        }
    }
    
    func testShowsInitialRegisteredStatus() {
        let vc = makeViewController(persistence: PersistenceDouble(registration: arbitraryRegistration()))
        
        XCTAssertEqual(vc.registrationStatusText?.text, "Everything is working OK")
        XCTAssertEqual(vc.registrationStatusIcon?.image, UIImage(named: "Registration_status_ok"))
        XCTAssertFalse(vc.registrationStatusIcon?.isHidden ?? true)
        XCTAssertTrue(vc.registrationSpinner?.isHidden ?? false)
        XCTAssertNil(vc.registratonStatusView?.backgroundColor)
        XCTAssertEqual(vc.registrationStatusText?.textColor, UIColor(named: "NHS Text"))
        XCTAssertTrue(vc.registrationRetryButton?.isHidden ?? false)
    }
    
    func testShowsInitialInProgressStatus() {
        let vc = makeViewController(persistence: PersistenceDouble(registration: nil))
        
        XCTAssertEqual(vc.registrationStatusText?.text, "Finalising setup...")
        XCTAssertTrue(vc.registrationStatusIcon?.isHidden ?? false)
        XCTAssertFalse(vc.registrationSpinner?.isHidden ?? true)
        XCTAssertNil(vc.registratonStatusView?.backgroundColor)
        XCTAssertEqual(vc.registrationStatusText?.textColor, UIColor(named: "NHS Text"))
        XCTAssertTrue(vc.registrationRetryButton?.isHidden ?? false)
    }
    
    func testStartsRegistrationOnShownWhenNotAlreadyRegistered() {
        let registrationService = RegistrationServiceDouble()
        _ = makeViewController(persistence: PersistenceDouble(registration: nil), registrationService: registrationService)
        
        XCTAssertTrue(registrationService.registerCalled)
    }
    
    func testUpdatesAfterRegistrationCompletes() {
        let registrationService = RegistrationServiceDouble()
        let notificationCenter = NotificationCenter()
        let vc = makeViewController(persistence: PersistenceDouble(registration: nil), registrationService: registrationService, notificationCenter: notificationCenter)

        notificationCenter.post(name: RegistrationCompletedNotification, object: nil)
        
        XCTAssertEqual(vc.registrationStatusText?.text, "Everything is working OK")
        XCTAssertEqual(vc.registrationStatusIcon?.image, UIImage(named: "Registration_status_ok"))
        XCTAssertFalse(vc.registrationStatusIcon?.isHidden ?? true)
        XCTAssertTrue(vc.registrationSpinner?.isHidden ?? false)
        XCTAssertNil(vc.registratonStatusView?.backgroundColor)
        XCTAssertEqual(vc.registrationStatusText?.textColor, UIColor(named: "NHS Text"))
        XCTAssertTrue(vc.registrationRetryButton?.isHidden ?? false)
    }
    
    func testUpdatesAfterRegistrationFails() {
        let registrationService = RegistrationServiceDouble()
        let notificationCenter = NotificationCenter()
        let vc = makeViewController(persistence: PersistenceDouble(registration: nil), registrationService: registrationService, notificationCenter: notificationCenter)

        notificationCenter.post(name: RegistrationFailedNotification, object: nil)

        XCTAssertEqual(vc.registrationStatusText?.text, "App setup failed")
        XCTAssertEqual(vc.registrationStatusIcon?.image, UIImage(named: "Registration_status_failure"))
        XCTAssertFalse(vc.registrationStatusIcon?.isHidden ?? true)
        XCTAssertTrue(vc.registrationSpinner?.isHidden ?? false)
        XCTAssertEqual(vc.registratonStatusView?.backgroundColor, UIColor(named: "Error Grey"))
        XCTAssertEqual(vc.registrationStatusText?.textColor, UIColor.white)
        XCTAssertFalse(vc.registrationRetryButton?.isHidden ?? true)
    }
    
    func testRetry() {
        let registrationService = RegistrationServiceDouble()
        let queueDouble = QueueDouble()
        let vc = makeViewController(persistence: PersistenceDouble(registration: nil), registrationService: registrationService)
        
        queueDouble.scheduledBlock?()
        
        registrationService.registerCalled = false
        vc.retryRegistrationTapped()
        
        XCTAssertTrue(registrationService.registerCalled)

        XCTAssertEqual(vc.registrationStatusText?.text, "Finalising setup...")
        XCTAssertTrue(vc.registrationStatusIcon?.isHidden ?? false)
        XCTAssertFalse(vc.registrationSpinner?.isHidden ?? true)
        XCTAssertNil(vc.registratonStatusView?.backgroundColor)
        XCTAssertEqual(vc.registrationStatusText?.textColor, UIColor(named: "NHS Text"))
        XCTAssertTrue(vc.registrationRetryButton?.isHidden ?? false)
    }

    func arbitraryRegistration() -> Registration {
        return Registration(id: UUID(), secretKey: Data())
    }
}

fileprivate func makeViewController(
    persistence: Persisting,
    registrationService: RegistrationService = RegistrationServiceDouble(),
    notificationCenter: NotificationCenter = NotificationCenter()
) -> StatusViewController {
    let vc = StatusViewController.instantiate()
    vc.inject(
        persistence: persistence,
        registrationService: registrationService,
        contactEventRepo: ContactEventRepositoryDouble(),
        session: SessionDouble(),
        notificationCenter: notificationCenter
    )
    XCTAssertNotNil(vc.view)
    vc.viewWillAppear(false)
    return vc
}
