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
        let statusStateMachine = StatusStateMachiningDouble(state: .ok(StatusState.Ok()))
        let vc = makeViewController(
            notificationCenter: notificationCenter,
            statusStateMachine: statusStateMachine
        )
        XCTAssertEqual(vc.diagnosisTitleLabel.text, "Follow the current advice to stop the spread of coronavirus".localized)

        statusStateMachine.state = .exposed(StatusState.Exposed(startDate: Date()))
        notificationCenter.post(name: StatusStateMachine.StatusStateChangedNotification, object: nil)

        XCTAssertEqual(vc.diagnosisTitleLabel.text, "You have been near someone who has coronavirus symptoms".localized)
    }
    
    func testShowsOkStatus() throws {
        let statusStateMachine = StatusStateMachiningDouble(state: .ok(StatusState.Ok()))
        let vc = makeViewController(persistence: PersistenceDouble(), statusStateMachine: statusStateMachine)
        
        XCTAssertTrue(vc.diagnosisDetailLabel.isHidden)
        XCTAssertEqual(vc.diagnosisTitleLabel.text, "Follow the current advice to stop the spread of coronavirus")
    }
    
    func testShowsExposedStatus() throws {
        let statusStateMachine = StatusStateMachiningDouble(state: .exposed(StatusState.Exposed(startDate: Date())))
        let vc = makeViewController(statusStateMachine: statusStateMachine)

        XCTAssertFalse(vc.diagnosisDetailLabel.isHidden)

        XCTAssertEqual(vc.diagnosisDetailLabel.text, "Mantain social distancing and wash your hands frequently. Read advice for you below.")

        XCTAssertEqual(vc.diagnosisTitleLabel.text, "You have been near someone who has coronavirus symptoms")
    }
    
    func testShowsSymptomaticStatusForInitialSelfDiagnosis() {
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

    func testShowsSymptomaticStatusForCheckin() {
        let statusStateMachine = StatusStateMachiningDouble(
            state: .checkin(StatusState.Checkin(symptoms: [.temperature], checkinDate: Date()))
        )
        let vc = makeViewController(statusStateMachine: statusStateMachine)
        
        XCTAssertEqual(vc.diagnosisTitleLabel.text, "Your symptoms indicate you may have coronavirus. Please self-isolate and apply for a test.")
        XCTAssertFalse(vc.diagnosisDetailLabel.isHidden)
        XCTAssertEqual(vc.diagnosisDetailLabel.text, "Follow this advice until your temperature returns to normal.")
    }
    
    func testShowsCorrectAdviceInOkStatus() throws {
        let vc = makeViewController(
            persistence: PersistenceDouble(),
            statusStateMachine: StatusStateMachiningDouble(state: .ok(StatusState.Ok()))
        )
        let navigationController = SynchronousNavigationControllerDouble()
        navigationController.viewControllers = [vc]
        
        vc.adviceTapped()
        
        let adviceVc = try XCTUnwrap(vc.navigationController?.viewControllers.last as? AdviceViewController)
        XCTAssertNotNil(adviceVc.view)
        XCTAssertEqual(adviceVc.link.url, URL(string: "https://faq.covid19.nhs.uk/article/KA-01062/en-us"))
    }
    
    func testShowsCorrectAdviceInExposedStatus() throws {
        let vc = makeViewController(
            persistence: PersistenceDouble(),
            statusStateMachine: StatusStateMachiningDouble(state: .exposed(StatusState.Exposed(startDate: Date())))
        )
        let navigationController = SynchronousNavigationControllerDouble()
        navigationController.viewControllers = [vc]
        
        vc.adviceTapped()
        
        let adviceVc = try XCTUnwrap(vc.navigationController?.viewControllers.last as? AdviceViewController)
        XCTAssertNotNil(adviceVc.view)
        XCTAssertEqual(adviceVc.link.url, URL(string: "https://faq.covid19.nhs.uk/article/KA-01063/en-us"))
    }
    
    func testShowsCorrectAdviceInSymptomaticStatus() throws {
        let vc = makeViewController(
            persistence: PersistenceDouble(),
            statusStateMachine: StatusStateMachiningDouble(state: .symptomatic(StatusState.Symptomatic(symptoms: [], startDate: Date())))
        )
        let navigationController = SynchronousNavigationControllerDouble()
        navigationController.viewControllers = [vc]
        
        vc.adviceTapped()
        
        let adviceVc = try XCTUnwrap(vc.navigationController?.viewControllers.last as? AdviceViewController)
        XCTAssertNotNil(adviceVc.view)
        XCTAssertEqual(adviceVc.link.url, URL(string: "https://faq.covid19.nhs.uk/article/KA-01078/en-us"))
    }
    
    func testShowsCorrectAdviceInPositiveTestStatus() throws {
        let vc = makeViewController(
            persistence: PersistenceDouble(),
            statusStateMachine: StatusStateMachiningDouble(state: .positiveTestResult(StatusState.PositiveTestResult(symptoms: [], startDate: Date())))
        )
        let navigationController = SynchronousNavigationControllerDouble()
        navigationController.viewControllers = [vc]
        
        vc.adviceTapped()
        
        let adviceVc = try XCTUnwrap(vc.navigationController?.viewControllers.last as? AdviceViewController)
        XCTAssertNotNil(adviceVc.view)
        XCTAssertEqual(adviceVc.link.url, URL(string: "https://faq.covid19.nhs.uk/article/KA-01064/en-us"))
    }
}

fileprivate func makeViewController(
    persistence: Persisting = PersistenceDouble(),
    registrationService: RegistrationService = RegistrationServiceDouble(),
    notificationCenter: NotificationCenter = NotificationCenter(),
    statusStateMachine: StatusStateMachining = StatusStateMachiningDouble(state: .ok(StatusState.Ok())),
    loadView: Bool = true
) -> StatusViewController {
    let vc = StatusViewController.instantiate()
    vc.inject(
        statusStateMachine: statusStateMachine,
        userStatusProvider: UserStatusProvider(localeProvider: EnGbLocaleProviderDouble()),
        persistence: persistence,
        linkingIdManager: LinkingIdManagerDouble(),
        registrationService: registrationService,
        notificationCenter: notificationCenter
    )
    if loadView {
        XCTAssertNotNil(vc.view)
        vc.viewWillAppear(false)
    }
    return vc
}

fileprivate class SynchronousNavigationControllerDouble: UINavigationController {
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        viewControllers.append(viewController)
    }
}
