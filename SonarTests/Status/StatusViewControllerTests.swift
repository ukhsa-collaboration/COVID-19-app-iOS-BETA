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

    func testUnhidingNotificationStatusViewBeforeViewDidLoadShowsNotificationStatusView() {
        let vc = makeViewController(persistence: PersistenceDouble(registration: Registration.fake), loadView: false)
        vc.hasNotificationProblem = false
        
        XCTAssertNotNil(vc.view)
        vc.viewWillAppear(false)
        
        XCTAssert(vc.notificationsStatusView.isHidden)
    }
    
    func testDisablingNotificationsStatusView() {
        let persistance = PersistenceDouble(registration: Registration.fake)
        let vc = makeViewController(persistence: persistance)

        vc.hasNotificationProblem = true
        XCTAssertFalse(vc.notificationsStatusView.isHidden)

        vc.disableNotificationsTapped()
        
        XCTAssert(vc.notificationsStatusView.isHidden)
        XCTAssert(persistance.disabledNotificationsStatusView)
    }
    
    func testPredisabledNotificationsStatusView() {
        let persistance = PersistenceDouble(registration: Registration.fake)
        persistance.disabledNotificationsStatusView = true
        
        let vc = makeViewController(persistence: persistance)
        vc.hasNotificationProblem = true

        XCTAssert(vc.notificationsStatusView.isHidden)
    }
    
    func testReloadsOnPotentiallyExposedNotification() {
        let notificationCenter = NotificationCenter()
        let statusStateMachine = StatusStateMachiningDouble()
        let vc = makeViewController(
            notificationCenter: notificationCenter,
            statusStateMachine: statusStateMachine
        )
        XCTAssertEqual(vc.diagnosisTitleLabel.text, "Follow the current advice to stop the spread of coronavirus".localized)

        statusStateMachine.state = .exposed(StatusState.Exposed(exposureDate: Date()))
        notificationCenter.post(name: StatusStateMachine.StatusStateChangedNotification, object: nil)

        XCTAssertEqual(vc.diagnosisTitleLabel.text, "You have been near someone who has coronavirus symptoms".localized)
    }
    
    func testShowsBlueStatus() throws {
        throw XCTSkip("TODO: make this work for all time zones and on CI")

//        let midnightUTC = 1589414400
//        let midnightLocal = midnightUTC - TimeZone.current.secondsFromGMT()
//        let currentDate = Date.init(timeIntervalSince1970: TimeInterval(midnightLocal))
        
        let statusStateMachine = StatusStateMachiningDouble()
        let vc = makeViewController(persistence: PersistenceDouble(), statusStateMachine: statusStateMachine)
        
        XCTAssertFalse(vc.diagnosisDetailLabel.isHidden)
        XCTAssertEqual(vc.diagnosisDetailLabel.text, "Valid as of 7 May")
        XCTAssertEqual(vc.diagnosisTitleLabel.text, "Follow the current advice to stop the spread of coronavirus")
    }
    
    func testShowsAmberStatus() throws {
        throw XCTSkip("TODO: make this work for all time zones and on CI")

        // Since we inject in a GB locale but calculate expiry using the current calendar,
        // we do these shenanigans to get a suitable date to result in 28 May being the
        // expiry in GB time.
        let exposureDate = Calendar.current
            .date(from: DateComponents(month: 5, day: 14))!
            .addingTimeInterval(TimeInterval(-TimeZone.current.secondsFromGMT()))

        let statusStateMachine = StatusStateMachiningDouble(state: .exposed(StatusState.Exposed(exposureDate: exposureDate)))
        let vc = makeViewController(statusStateMachine: statusStateMachine)

        XCTAssertFalse(vc.diagnosisDetailLabel.isHidden)

        //
        XCTAssertEqual(vc.diagnosisDetailLabel.text, "Follow this advice until 28 May")

        XCTAssertEqual(vc.diagnosisTitleLabel.text, "You have been near someone who has coronavirus symptoms")
    }
    
    func testShowsRedStatusForInitialSelfDiagnosis() {
        let startDate = Calendar.current.date(from: DateComponents(month: 5, day: 7))!
        let statusStateMachine = StatusStateMachiningDouble(
            state: .symptomatic(StatusState.Symptomatic(
                symptoms: [.cough],
                startDate: startDate
            ))
        )
        let vc = makeViewController(statusStateMachine: statusStateMachine)
        
        XCTAssertEqual(vc.diagnosisTitleLabel.text, "Your symptoms indicate you may have coronavirus. Please self-isolate and apply for a test.")
        XCTAssertFalse(vc.diagnosisDetailLabel.isHidden)
        XCTAssertEqual(vc.diagnosisDetailLabel.text, "On 14 May this app will notify you to update your symptoms. Please read your full advice below.")
    }

    func testShowsRedStatusForCheckin() {
        let statusStateMachine = StatusStateMachiningDouble(
            state: .checkin(StatusState.Checkin(symptoms: [.temperature], checkinDate: Date()))
        )
        let vc = makeViewController(statusStateMachine: statusStateMachine)
        
        XCTAssertEqual(vc.diagnosisTitleLabel.text, "Your symptoms indicate you may have coronavirus. Please self-isolate and apply for a test.")
        XCTAssertFalse(vc.diagnosisDetailLabel.isHidden)
        XCTAssertEqual(vc.diagnosisDetailLabel.text, "Follow this advice until your temperature returns to normal.")
    }
}

fileprivate func makeViewController(
    persistence: Persisting = PersistenceDouble(),
    registrationService: RegistrationService = RegistrationServiceDouble(),
    notificationCenter: NotificationCenter = NotificationCenter(),
    statusStateMachine: StatusStateMachining = StatusStateMachiningDouble(),
    loadView: Bool = true
) -> StatusViewController {
    let vc = StatusViewController.instantiate()
    vc.inject(
        statusStateMachine: statusStateMachine,
        userStatusProvider: UserStatusProvider(localeProvider: EnGbLocaleProviderDouble()),
        persistence: persistence,
        linkingIdManager: LinkingIdManagerDouble(),
        registrationService: registrationService,
        notificationCenter: notificationCenter,
        urlOpener: UIApplication.shared
    )
    if loadView {
        XCTAssertNotNil(vc.view)
        vc.viewWillAppear(false)
    }
    return vc
}
