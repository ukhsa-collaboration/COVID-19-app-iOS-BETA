//
//  RegistrationStatusViewControllerTests.swift
//  SonarTests
//
//  Created by NHSX on 5/19/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class RegistrationStatusViewControllerTests: XCTestCase {

    var vc: RegistrationStatusViewController!

    var persistence: PersistenceDouble!
    var registrationService: RegistrationServiceDouble!
    var notificationCenter: NotificationCenter!

    override func setUp() {
        persistence = PersistenceDouble()
        registrationService = RegistrationServiceDouble()
        notificationCenter = NotificationCenter()
    }

    func testShowsInitialRegisteredStatus() {
        vc = makeSubject(registration: Registration.fake)

        XCTAssertEqual(vc.registrationStatusText?.text, "The app is working properly")
        XCTAssertEqual(vc.registrationStatusIcon?.image, UIImage(named: "Registration_status_ok"))
        XCTAssertFalse(vc.registrationStatusIcon?.isHidden ?? true)
        XCTAssertTrue(vc.registrationSpinner?.isHidden ?? false)
        XCTAssertNil(vc.view?.backgroundColor)
        XCTAssertEqual(vc.registrationStatusText?.textColor, UIColor.nhs.text)
        XCTAssertTrue(vc.registrationRetryButton?.isHidden ?? false)
    }

    func testShowsInitialInProgressStatus() {
        vc = makeSubject(registration: nil)

        XCTAssertEqual(vc.registrationStatusText?.text, "Finalising setup...")
        XCTAssertTrue(vc.registrationStatusIcon?.isHidden ?? false)
        XCTAssertFalse(vc.registrationSpinner?.isHidden ?? true)
        XCTAssertNil(vc.view?.backgroundColor)
        XCTAssertEqual(vc.registrationStatusText?.textColor, UIColor.nhs.text)
        XCTAssertTrue(vc.registrationRetryButton?.isHidden ?? false)
    }

    func testStartsRegistrationOnShownWhenNotAlreadyRegistered() {
        vc = makeSubject(registration: nil)

        XCTAssertTrue(registrationService.registerCalled)
    }

    func testUpdatesAfterRegistrationCompletes() {
        vc = makeSubject(registration: nil)

        notificationCenter.post(name: RegistrationCompletedNotification, object: nil)

        XCTAssertEqual(vc.registrationStatusText?.text, "The app is working properly")
        XCTAssertEqual(vc.registrationStatusIcon?.image, UIImage(named: "Registration_status_ok"))
        XCTAssertFalse(vc.registrationStatusIcon?.isHidden ?? true)
        XCTAssertTrue(vc.registrationSpinner?.isHidden ?? false)
        XCTAssertNil(vc.view?.backgroundColor)
        XCTAssertEqual(vc.registrationStatusText?.textColor, UIColor.nhs.text)
        XCTAssertTrue(vc.registrationRetryButton?.isHidden ?? false)
    }

    func testUpdatesAfterRegistrationFails() {
        vc = makeSubject(registration: nil)

        notificationCenter.post(name: RegistrationFailedNotification, object: nil)

        XCTAssertEqual(vc.registrationStatusText?.text, "App setup failed")
        XCTAssertEqual(vc.registrationStatusIcon?.image, UIImage(named: "Registration_status_failure"))
        XCTAssertFalse(vc.registrationStatusIcon?.isHidden ?? true)
        XCTAssertTrue(vc.registrationSpinner?.isHidden ?? false)
        XCTAssertEqual(vc.view?.backgroundColor, UIColor.nhs.errorGrey)
        XCTAssertEqual(vc.registrationStatusText?.textColor, UIColor.white)
        XCTAssertFalse(vc.registrationRetryButton?.isHidden ?? true)
    }

    func testRetry() {
        let queueDouble = QueueDouble()
        vc = makeSubject(registration: nil)

        queueDouble.scheduledBlock?()

        registrationService.registerCalled = false
        vc.retryRegistrationTapped()

        XCTAssertTrue(registrationService.registerCalled)

        XCTAssertEqual(vc.registrationStatusText?.text, "Finalising setup...")
        XCTAssertTrue(vc.registrationStatusIcon?.isHidden ?? false)
        XCTAssertFalse(vc.registrationSpinner?.isHidden ?? true)
        XCTAssertNil(vc.view?.backgroundColor)
        XCTAssertEqual(vc.registrationStatusText?.textColor, UIColor.nhs.text)
        XCTAssertTrue(vc.registrationRetryButton?.isHidden ?? false)
    }

    private func makeSubject(registration: Registration? = nil) -> RegistrationStatusViewController {
        persistence.registration = registration

        vc = RegistrationStatusViewController.instantiate()
        vc.inject(
            persistence: persistence,
            registrationService: registrationService,
            notificationCenter: notificationCenter
        )

        XCTAssertNotNil(vc.view)
        vc.viewWillAppear(false)

        return vc
    }

}
