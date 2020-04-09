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
    
    func testShowsInitialRegisteredStatus() {
        let vc = StatusViewController.instantiate()
        vc.inject(persistence: PersistenceDouble(registration: arbitraryRegistration()), registrationService: RegistrationServiceDouble(), mainQueue: AsyncAfterableDouble())
        XCTAssertNotNil(vc.view)
        
        XCTAssertEqual(vc.registrationStatusText?.text, "Everything is working OK")
        XCTAssertEqual(vc.registrationStatusIcon?.image, UIImage(named: "Registration_status_ok"))
        XCTAssertFalse(vc.registrationStatusIcon?.isHidden ?? true)
        XCTAssertTrue(vc.registrationSpinner?.isHidden ?? false)
        XCTAssertNil(vc.registratonStatusView?.backgroundColor)
        XCTAssertEqual(vc.registrationStatusText?.textColor, UIColor(named: "NHS Text"))
        XCTAssertTrue(vc.registrationRetryButton?.isHidden ?? false)
    }
    
    func testShowsInitialInProgressStatus() {
        let vc = StatusViewController.instantiate()
        vc.inject(persistence: PersistenceDouble(registration: nil), registrationService: RegistrationServiceDouble(), mainQueue: AsyncAfterableDouble())
        XCTAssertNotNil(vc.view)
        
        XCTAssertEqual(vc.registrationStatusText?.text, "Finalising setup...")
        XCTAssertTrue(vc.registrationStatusIcon?.isHidden ?? false)
        XCTAssertFalse(vc.registrationSpinner?.isHidden ?? true)
        XCTAssertNil(vc.registratonStatusView?.backgroundColor)
        XCTAssertEqual(vc.registrationStatusText?.textColor, UIColor(named: "NHS Text"))
        XCTAssertTrue(vc.registrationRetryButton?.isHidden ?? false)
    }
    
    func testStartsRegistrationOnShownWhenNotAlreadyRegistered() {
        let vc = StatusViewController.instantiate()
        let registrationService = RegistrationServiceDouble()
        vc.inject(persistence: PersistenceDouble(registration: nil), registrationService: registrationService, mainQueue: AsyncAfterableDouble())
        XCTAssertNotNil(vc.view)
        
        XCTAssertNotNil(registrationService.lastAttempt)
    }
    
    func testUpdatesAfterRegistrationCompletes() {
        let vc = StatusViewController.instantiate()
        let registrationService = RegistrationServiceDouble()
        vc.inject(persistence: PersistenceDouble(registration: nil), registrationService: registrationService, mainQueue: AsyncAfterableDouble())
        XCTAssertNotNil(vc.view)
        
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
        let vc = StatusViewController.instantiate()
        let registrationService = RegistrationServiceDouble()
        vc.inject(persistence: PersistenceDouble(registration: nil), registrationService: registrationService, mainQueue: AsyncAfterableDouble())
        XCTAssertNotNil(vc.view)
        
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
        let vc = StatusViewController.instantiate()
        let registrationService = RegistrationServiceDouble()
        let asyncAfterable = AsyncAfterableDouble()
        vc.inject(persistence: PersistenceDouble(registration: nil), registrationService: registrationService, mainQueue: asyncAfterable)
        XCTAssertNotNil(vc.view)
        
        asyncAfterable.scheduledBlock?()
        
        XCTAssertEqual(vc.registrationStatusText?.text, "App setup failed")
        XCTAssertEqual(vc.registrationStatusIcon?.image, UIImage(named: "Registration_status_failure"))
        XCTAssertFalse(vc.registrationStatusIcon?.isHidden ?? true)
        XCTAssertTrue(vc.registrationSpinner?.isHidden ?? false)
        XCTAssertEqual(vc.registratonStatusView?.backgroundColor, UIColor(named: "Error Grey"))
        XCTAssertEqual(vc.registrationStatusText?.textColor, UIColor.white)
        XCTAssertFalse(vc.registrationRetryButton?.isHidden ?? true)
    }
    
    func testDoesNotShowFailureAfter20SecondsIfSucceeded() {
        let vc = StatusViewController.instantiate()
        let registrationService = RegistrationServiceDouble()
        let asyncAfterable = AsyncAfterableDouble()
        vc.inject(persistence: PersistenceDouble(registration: nil), registrationService: registrationService, mainQueue: asyncAfterable)
        XCTAssertNotNil(vc.view)
        
        registrationService.completionHandler?(Result<(), Error>.success(()))
        asyncAfterable.scheduledBlock?()
        
        XCTAssertEqual(vc.registrationStatusText?.text, "Everything is working OK")
        XCTAssertEqual(vc.registrationStatusIcon?.image, UIImage(named: "Registration_status_ok"))
        XCTAssertFalse(vc.registrationStatusIcon?.isHidden ?? true)
        XCTAssertTrue(vc.registrationSpinner?.isHidden ?? false)
        XCTAssertNil(vc.registratonStatusView?.backgroundColor)
        XCTAssertEqual(vc.registrationStatusText?.textColor, UIColor(named: "NHS Text"))
    }
    
    func testCancelsAfter20Seconds() {
        let vc = StatusViewController.instantiate()
        let registrationService = RegistrationServiceDouble()
        let asyncAfterable = AsyncAfterableDouble()
        vc.inject(persistence: PersistenceDouble(registration: nil), registrationService: registrationService, mainQueue: asyncAfterable)
        XCTAssertNotNil(vc.view)
        
        asyncAfterable.scheduledBlock?()

        XCTAssertTrue((registrationService.lastAttempt as? CancelableDouble)?.canceled ?? false)
    }
    
    func testRetry() {
        let vc = StatusViewController.instantiate()
        let registrationService = RegistrationServiceDouble()
        let asyncAfterable = AsyncAfterableDouble()
        vc.inject(persistence: PersistenceDouble(registration: nil), registrationService: registrationService, mainQueue: asyncAfterable)
        XCTAssertNotNil(vc.view)
        
        asyncAfterable.scheduledBlock?()
        
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
