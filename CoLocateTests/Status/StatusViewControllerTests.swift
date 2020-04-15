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
        let permutations: [(SelfDiagnosis, Bool, StatusViewController.Status)] = [
            (.notInfected, false, .initial),
            (.notInfected, true, .amber),
            (.infected, false, .red),
            (.infected, true, .red),
        ]

        for (diagnosis, potentiallyExposed, expectedStatus) in permutations {
            let persistence = PersistenceDouble(potentiallyExposed: potentiallyExposed, diagnosis: diagnosis)
            let vc = makeViewController(persistence: persistence)

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
        
        XCTAssertNotNil(registrationService.lastAttempt)
    }
    
    func testUpdatesAfterRegistrationCompletes() {
        let registrationService = RegistrationServiceDouble()
        let vc = makeViewController(persistence: PersistenceDouble(registration: nil), registrationService: registrationService)

        registrationService.completionHandler?(Result<(), Error>.success(()))
        
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
        let vc = makeViewController(persistence: PersistenceDouble(registration: nil), registrationService: registrationService)
        
        registrationService.completionHandler?(Result<(), Error>.failure(ErrorForTest()))
        
        XCTAssertEqual(vc.registrationStatusText?.text, "App setup failed")
        XCTAssertEqual(vc.registrationStatusIcon?.image, UIImage(named: "Registration_status_failure"))
        XCTAssertFalse(vc.registrationStatusIcon?.isHidden ?? true)
        XCTAssertTrue(vc.registrationSpinner?.isHidden ?? false)
        XCTAssertEqual(vc.registratonStatusView?.backgroundColor, UIColor(named: "Error Grey"))
        XCTAssertEqual(vc.registrationStatusText?.textColor, UIColor.white)
        XCTAssertFalse(vc.registrationRetryButton?.isHidden ?? true)
    }
    
    func testShowsFailureAfter20Seconds() {
        let registrationService = RegistrationServiceDouble()
        let queueDouble = QueueDouble()
        let vc = makeViewController(persistence: PersistenceDouble(registration: nil), registrationService: registrationService, mainQueue: queueDouble)
        
        queueDouble.scheduledBlock?()
        
        XCTAssertEqual(vc.registrationStatusText?.text, "App setup failed")
        XCTAssertEqual(vc.registrationStatusIcon?.image, UIImage(named: "Registration_status_failure"))
        XCTAssertFalse(vc.registrationStatusIcon?.isHidden ?? true)
        XCTAssertTrue(vc.registrationSpinner?.isHidden ?? false)
        XCTAssertEqual(vc.registratonStatusView?.backgroundColor, UIColor(named: "Error Grey"))
        XCTAssertEqual(vc.registrationStatusText?.textColor, UIColor.white)
        XCTAssertFalse(vc.registrationRetryButton?.isHidden ?? true)
    }
    
    func testDoesNotShowFailureAfter20SecondsIfSucceeded() {
        let registrationService = RegistrationServiceDouble()
        let queueDouble = QueueDouble()
        let vc = makeViewController(persistence: PersistenceDouble(registration: nil), registrationService: registrationService, mainQueue: queueDouble)

        registrationService.completionHandler?(Result<(), Error>.success(()))
        queueDouble.scheduledBlock?()
        
        XCTAssertEqual(vc.registrationStatusText?.text, "Everything is working OK")
        XCTAssertEqual(vc.registrationStatusIcon?.image, UIImage(named: "Registration_status_ok"))
        XCTAssertFalse(vc.registrationStatusIcon?.isHidden ?? true)
        XCTAssertTrue(vc.registrationSpinner?.isHidden ?? false)
        XCTAssertNil(vc.registratonStatusView?.backgroundColor)
        XCTAssertEqual(vc.registrationStatusText?.textColor, UIColor(named: "NHS Text"))
    }
    
    func testCancelsAfter20Seconds() {
        let registrationService = RegistrationServiceDouble()
        let queueDouble = QueueDouble()
        _ = makeViewController(persistence: PersistenceDouble(registration: nil), registrationService: registrationService, mainQueue: queueDouble)
        
        queueDouble.scheduledBlock?()

        XCTAssertTrue((registrationService.lastAttempt as? CancelableDouble)?.canceled ?? false)
    }
    
    func testRetry() {
        let registrationService = RegistrationServiceDouble()
        let queueDouble = QueueDouble()
        let vc = makeViewController(persistence: PersistenceDouble(registration: nil), registrationService: registrationService, mainQueue: queueDouble)
        
        queueDouble.scheduledBlock?()
        
        registrationService.lastAttempt = nil
        vc.retryRegistrationTapped()
        
        XCTAssertNotNil(registrationService.lastAttempt)

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
    mainQueue: TestableQueue = QueueDouble()
) -> StatusViewController {
    let vc = StatusViewController.instantiate()
    vc.inject(persistence: persistence, registrationService: registrationService, mainQueue: mainQueue, contactEventRepo: ContactEventRepositoryDouble(), session: SessionDouble())
    XCTAssertNotNil(vc.view)
    return vc
}
