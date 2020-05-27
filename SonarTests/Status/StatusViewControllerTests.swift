//
//  StatusViewControllerTests.swift
//  SonarTests
//
//  Created by NHSX on 4/8/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class StatusViewControllerTests: TestCase {

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
                startDate: startDate,
                checkinDate: StatusState.Symptomatic.firstCheckin(from: startDate)
            ))
        )
        let vc = makeViewController(statusStateMachine: statusStateMachine)
        
        XCTAssertEqual(vc.diagnosisTitleLabel.text, "Your symptoms indicate you may have coronavirus. Please self-isolate and apply for a test.")
        XCTAssertFalse(vc.diagnosisDetailLabel.isHidden)
        XCTAssertEqual(vc.diagnosisDetailLabel.text, "On 14 May this app will notify you to update your symptoms. Please read your full advice below.")
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
        XCTAssertEqual(adviceVc.detail.text, "The advice below is up-to-date and specific to your situation. Please follow this advice.")
    }
    
    func testShowsCorrectAdviceInExposedStatus() throws {
        let exposureDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 30))!
        let vc = makeViewController(
            persistence: PersistenceDouble(),
            statusStateMachine: StatusStateMachiningDouble(state: .exposed(StatusState.Exposed(startDate: exposureDate)))
        )
        let navigationController = SynchronousNavigationControllerDouble()
        navigationController.viewControllers = [vc]
        
        vc.adviceTapped()
        
        let adviceVc = try XCTUnwrap(vc.navigationController?.viewControllers.last as? AdviceViewController)
        XCTAssertNotNil(adviceVc.view)
        XCTAssertEqual(adviceVc.link.url, URL(string: "https://faq.covid19.nhs.uk/article/KA-01063/en-us"))
        XCTAssertEqual(adviceVc.detail.text, "The advice below is up-to-date and specific to your situation. Follow this advice until 14 May 2020.")
    }
    
    func testShowsCorrectAdviceInSymptomaticStatus() throws {
        let vc = makeViewController(
            persistence: PersistenceDouble(),
            statusStateMachine: StatusStateMachiningDouble(state: .symptomatic(StatusState.Symptomatic(symptoms: [], startDate: Date(), checkinDate: Date())))
        )
        let navigationController = SynchronousNavigationControllerDouble()
        navigationController.viewControllers = [vc]
        
        vc.adviceTapped()
        
        let adviceVc = try XCTUnwrap(vc.navigationController?.viewControllers.last as? AdviceViewController)
        XCTAssertNotNil(adviceVc.view)
        XCTAssertEqual(adviceVc.link.url, URL(string: "https://faq.covid19.nhs.uk/article/KA-01078/en-us"))
        XCTAssertEqual(adviceVc.detail.text, "The advice below is up-to-date and specific to your situation. Please follow this advice.")
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
        XCTAssertEqual(adviceVc.detail.text, "The advice below is up-to-date and specific to your situation. Please follow this advice.")
    }
    
    func testShowsDrawerAfterCheckinIfCoughButNoTemperature() throws {
        try PresentationSpy.withSpy {
            let persistence = PersistenceDouble(statusState: .symptomatic(StatusState.Symptomatic(symptoms: [], startDate: Date(), checkinDate: Date())))
            let statusStateMachine = StatusStateMachine(persisting: persistence, contactEventsUploader: ContactEventsUploaderDouble(), notificationCenter: NotificationCenter(), userNotificationCenter: UserNotificationCenterDouble())
            let drawerPresenter = DrawerPresenterDouble()
            let vc = makeViewController(
                persistence: persistence,
                statusStateMachine: statusStateMachine,
                loadView: true,
                makePresentSynchronous: true,
                drawerPresenter: drawerPresenter
            )
        
            let promptVc = try XCTUnwrap(PresentationSpy.presented(by: vc) as? SymptomsPromptViewController)
            promptVc.updateSymptoms()
            try respondToSymptomQuestion(vc: vc, expectedTitle: "TEMPERATURE_QUESTION", response: false)
            try respondToSymptomQuestion(vc: vc, expectedTitle: "COUGH_QUESTION", response: true)
            try respondToSymptomQuestion(vc: vc, expectedTitle: "ANOSMIA_QUESTION", response: false)
            
            XCTAssertNotNil(drawerPresenter.presented as? DrawerViewController)
        }
    }

    
    func testShowsDrawerAfterCheckinIfAnosmiaButNoTemperature() throws {
        try PresentationSpy.withSpy {
            let persistence = PersistenceDouble(statusState: .symptomatic(StatusState.Symptomatic(symptoms: [], startDate: Date(), checkinDate: Date())))
            let statusStateMachine = StatusStateMachine(persisting: persistence, contactEventsUploader: ContactEventsUploaderDouble(), notificationCenter: NotificationCenter(), userNotificationCenter: UserNotificationCenterDouble())
            let drawerPresenter = DrawerPresenterDouble()
            let vc = makeViewController(
                persistence: persistence,
                statusStateMachine: statusStateMachine,
                loadView: true,
                makePresentSynchronous: true,
                drawerPresenter: drawerPresenter
            )

            let promptVc = try XCTUnwrap(PresentationSpy.presented(by: vc) as? SymptomsPromptViewController)
            promptVc.updateSymptoms()
            try respondToSymptomQuestion(vc: vc, expectedTitle: "TEMPERATURE_QUESTION", response: false)
            try respondToSymptomQuestion(vc: vc, expectedTitle: "COUGH_QUESTION", response: false)
            try respondToSymptomQuestion(vc: vc, expectedTitle: "ANOSMIA_QUESTION", response: true)
            
            XCTAssertNotNil(drawerPresenter.presented as? DrawerViewController)
        }
    }
    
    func testDoesNotShowsDrawerAfterCheckinIfTemperature() throws{
        try PresentationSpy.withSpy {
            let persistence = PersistenceDouble(statusState: .symptomatic(StatusState.Symptomatic(symptoms: [], startDate: Date(), checkinDate: Date())))
            let statusStateMachine = StatusStateMachine(persisting: persistence, contactEventsUploader: ContactEventsUploaderDouble(), notificationCenter: NotificationCenter(), userNotificationCenter: UserNotificationCenterDouble())
            let drawerPresenter = DrawerPresenterDouble()
            let vc = makeViewController(
                persistence: persistence,
                statusStateMachine: statusStateMachine,
                loadView: true,
                makePresentSynchronous: true,
                drawerPresenter: drawerPresenter
            )

            let promptVc = try XCTUnwrap(PresentationSpy.presented(by: vc) as? SymptomsPromptViewController)
            promptVc.updateSymptoms()
            try respondToSymptomQuestion(vc: vc, expectedTitle: "TEMPERATURE_QUESTION", response: true)
            try respondToSymptomQuestion(vc: vc, expectedTitle: "COUGH_QUESTION", response: false)
            try respondToSymptomQuestion(vc: vc, expectedTitle: "ANOSMIA_QUESTION", response: false)
            
            XCTAssertNil(drawerPresenter.presented)
        }
    }
    
    private func respondToSymptomQuestion(
        vc: StatusViewController,
        expectedTitle: String,
        response: Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let promptVc = try XCTUnwrap(vc.navigationController?.topViewController as? QuestionSymptomsViewController, file: file, line: line)
        XCTAssertEqual(promptVc.titleLabel.text, expectedTitle.localized, file: file, line: line)
        
        if response {
            promptVc.yesTapped()
        } else {
            promptVc.noTapped()
        }
        
        promptVc.continueTapped()
    }

    
    private func makeViewController(
        persistence: Persisting = PersistenceDouble(),
        registrationService: RegistrationService = RegistrationServiceDouble(),
        notificationCenter: NotificationCenter = NotificationCenter(),
        statusStateMachine: StatusStateMachining = StatusStateMachiningDouble(state: .ok(StatusState.Ok())),
        loadView: Bool = true,
        makePresentSynchronous: Bool = false,
        drawerPresenter: DrawerPresenter = DrawerPresenterDouble()
    ) -> StatusViewController {
        let vc = StatusViewController.instantiate()
        vc.inject(
            statusStateMachine: statusStateMachine,
            userStatusProvider: UserStatusProvider(localeProvider: EnGbLocaleProviderDouble()),
            persistence: persistence,
            linkingIdManager: LinkingIdManagerDouble(),
            registrationService: registrationService,
            notificationCenter: notificationCenter,
            drawerPresenter: drawerPresenter,
            localeProvider: EnGbLocaleProviderDouble()
        )
        
        vc.animateTransitions = !makePresentSynchronous
        
        if loadView {
            parentViewControllerForTests.pushViewController(vc, animated: false)
            XCTAssertNotNil(vc.view)
            vc.viewDidAppear(false)
        }
        return vc
    }
}

private class DrawerPresenterDouble: DrawerPresenter {
    var presented: UIViewController?
    
    func present(drawer: UIViewController, inNavigationController: UINavigationController, usingTransitioningDelegate: UIViewControllerTransitioningDelegate) {
        presented = drawer
    }
}
