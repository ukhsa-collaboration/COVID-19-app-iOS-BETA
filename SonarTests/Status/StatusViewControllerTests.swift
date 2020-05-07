//
//  StatusViewControllerTests.swift
//  SonarTests
//
//  Created by NHSX on 4/8/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class StatusViewControllerTests: XCTestCase {

    func testShowsInitialRegisteredStatus() {
        let vc = makeViewController(persistence: PersistenceDouble(registration: Registration.fake))
        
        XCTAssertEqual(vc.registrationStatusText?.text, "The app is working properly")
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
        
        XCTAssertEqual(vc.registrationStatusText?.text, "The app is working properly")
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

    func testReloadsOnPotentiallyExposedNotification() {
        let notificationCenter = NotificationCenter()
        let statusProvider = StatusProviderDouble.double()
        let vc = makeViewController(
            persistence: PersistenceDouble(),
            notificationCenter: notificationCenter,
            statusProvider: statusProvider
        )
        XCTAssertEqual(vc.diagnosisTitleLabel.text, "Follow the current advice to stop the spread of coronavirus".localized)

        statusProvider.status = .amber
        notificationCenter.post(name: PotentiallyExposedNotification, object: nil)

        XCTAssertEqual(vc.diagnosisTitleLabel.text, "You have been near someone who has coronavirus symptoms".localized)
    }
    
    func testShowsBlueStatus() {
        let midnightUTC = 1589414400
        let midnightLocal = midnightUTC - TimeZone.current.secondsFromGMT()
        let currentDate = Date.init(timeIntervalSince1970: TimeInterval(midnightLocal))
        
        let persistence = PersistenceDouble()
        let statusProvider = StatusProvider(persisting: persistence, currentDateProvider: { currentDate })
        let vc = makeViewController(persistence: PersistenceDouble(), statusProvider: statusProvider)
        
        XCTAssertFalse(vc.diagnosisDetailLabel.isHidden)
        XCTAssertEqual(vc.diagnosisDetailLabel.text, "Valid as of 7 May")
        XCTAssertEqual(vc.diagnosisTitleLabel.text, "Follow the current advice to stop the spread of coronavirus")
        XCTAssertTrue(vc.redStatusView.isHidden)
    }
    
    func testShowsAmberStatus() {
        let calendar = Calendar.current
        let midnightUTC = 1589414400
        let midnightLocal = midnightUTC - TimeZone.current.secondsFromGMT()
        let exposureDate = Date.init(timeIntervalSince1970: TimeInterval(midnightLocal))
        let currentDate = calendar.date(byAdding: .day, value: 10, to: exposureDate)!
        
        let persistence = PersistenceDouble()
        persistence.potentiallyExposed = exposureDate
        let statusProvider = StatusProvider(persisting: persistence, currentDateProvider: { currentDate })
        XCTAssertEqual(statusProvider.status, .amber)
        let vc = makeViewController(persistence: persistence, statusProvider: statusProvider)
        
        XCTAssertFalse(vc.diagnosisDetailLabel.isHidden)
        XCTAssertEqual(vc.diagnosisDetailLabel.text, "Follow this advice until 28 May")
        XCTAssertEqual(vc.diagnosisTitleLabel.text, "You have been near someone who has coronavirus symptoms")
        XCTAssertTrue(vc.redStatusView.isHidden)
    }
    
    func testShowsRedStatusForInitialSelfDiagnosis() {
        let persistence = PersistenceDouble()
        // Shenanigans to make the test pass in any time zone
        let midnightUTC = 1589414400
        let midnightLocal = midnightUTC - TimeZone.current.secondsFromGMT()
        let expiryDate = Date(timeIntervalSince1970: TimeInterval(midnightLocal))
        persistence.selfDiagnosis = SelfDiagnosis(
            type: .initial,
            symptoms: Set(arrayLiteral: Symptom.cough), // or temperature, or both
            startDate: Date(),
            expiryDate: expiryDate
        )
        let statusProvider = StatusProvider(persisting: persistence)
        XCTAssertEqual(statusProvider.status, .red)
        let vc = makeViewController(persistence: persistence, statusProvider: statusProvider)
        
        XCTAssertEqual(vc.diagnosisTitleLabel.text, "Your symptoms indicate you may have coronavirus")
        XCTAssertFalse(vc.diagnosisDetailLabel.isHidden)
        XCTAssertEqual(vc.diagnosisDetailLabel.text, "Follow this advice until 14 May, at which point this app will notify you to update your symptoms.")
        XCTAssertFalse(vc.redStatusView.isHidden)
    }

    func testShowsRedStatusForSubsequentSelfDiagnosisWithTemperature() {
        let statusProvider = StatusProviderDouble.double()
        statusProvider.status = .red
        let persistence = PersistenceDouble()
        persistence.selfDiagnosis = SelfDiagnosis(type: .subsequent, symptoms: Set(arrayLiteral: Symptom.temperature), startDate: Date())
        let vc = makeViewController(persistence: persistence, statusProvider: statusProvider)
        
        XCTAssertEqual(vc.diagnosisTitleLabel.text, "Your symptoms indicate you may have coronavirus")
        XCTAssertFalse(vc.diagnosisDetailLabel.isHidden)
        XCTAssertEqual(vc.diagnosisDetailLabel.text, "Follow this advice until your temperature returns to normal")
        XCTAssertFalse(vc.redStatusView.isHidden)
    }
    
    func testReadLatestAdviceLabelWhenDefaultStatus() {
        let statusProvider = StatusProviderDouble.double()
        statusProvider.status = .blue

        let persistence = PersistenceDouble()
        let vc = makeViewController(persistence: persistence, statusProvider: statusProvider)
        
        XCTAssertEqual(vc.readLatestAdviceLabel.text, "Read current advice")
    }

    func testReadLatestAdviceLabelWhenAmberStatus() {
        let statusProvider = StatusProviderDouble.double()
        statusProvider.status = .amber

        let persistence = PersistenceDouble()
        let vc = makeViewController(persistence: persistence, statusProvider: statusProvider)

        XCTAssertEqual(vc.readLatestAdviceLabel.text, "Read what to do next")
    }
    
    func testReadLatestAdviceLabelWhenRedStatus() {
        let statusProvider = StatusProviderDouble.double()
        statusProvider.status = .red

        let persistence = PersistenceDouble()
        let vc = makeViewController(persistence: persistence, statusProvider: statusProvider)

        XCTAssertEqual(vc.readLatestAdviceLabel.text, "Read what to do next")
    }
}

fileprivate func makeViewController(
    persistence: Persisting,
    registrationService: RegistrationService = RegistrationServiceDouble(),
    notificationCenter: NotificationCenter = NotificationCenter(),
    statusProvider: StatusProvider = StatusProviderDouble.double()
) -> StatusViewController {
    let vc = StatusViewController.instantiate()
    vc.inject(
        persistence: persistence,
        registrationService: registrationService,
        contactEventsUploader: ContactEventsUploaderDouble(),
        notificationCenter: notificationCenter,
        linkingIdManager: LinkingIdManagerDouble.make(),
        statusProvider: statusProvider,
        localeProvider: EnGbLocaleProviderDouble()
    )
    XCTAssertNotNil(vc.view)
    vc.viewWillAppear(false)
    return vc
}
