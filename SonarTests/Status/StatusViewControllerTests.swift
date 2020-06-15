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

        XCTAssertEqual(vc.diagnosisTitleLabel.text, "You have been near someone who has tested positive for coronavirus. Please self-isolate.".localized)
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
        XCTAssertEqual(vc.diagnosisTitleLabel.text, "You have been near someone who has tested positive for coronavirus. Please self-isolate.")
        // TODO: Do date maths to make this test valid.
        // XCTAssertEqual(vc.diagnosisDetailLabel.text, "Please follow the advice below until 14 May")
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
        
        XCTAssertEqual(vc.diagnosisTitleLabel.text, "Your symptoms indicate you may have coronavirus. Please isolate yourself and your household and book a test.")
        XCTAssertFalse(vc.diagnosisDetailLabel.isHidden)
        XCTAssertEqual(vc.diagnosisDetailLabel.text, "Please isolate until 14 May when this app will notify you to update your symptoms. Please read your full advice below.")
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
        let checkinDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 30))!
        let vc = makeViewController(
            persistence: PersistenceDouble(),
            statusStateMachine: StatusStateMachiningDouble(state: .symptomatic(StatusState.Symptomatic(symptoms: [], startDate: Date(), checkinDate: checkinDate)))
        )
        let navigationController = SynchronousNavigationControllerDouble()
        navigationController.viewControllers = [vc]
        
        vc.adviceTapped()
        
        let adviceVc = try XCTUnwrap(vc.navigationController?.viewControllers.last as? AdviceViewController)
        XCTAssertNotNil(adviceVc.view)
        XCTAssertEqual(adviceVc.link.url, URL(string: "https://faq.covid19.nhs.uk/article/KA-01078/en-us"))
        XCTAssertEqual(adviceVc.detail.text, "The advice below is up-to-date and specific to your situation. Follow this advice until 30 April 2020.")
    }
    
    func testShowsCorrectAdviceInPositiveTestStatus() throws {
        let startDate = Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 30))!
        let endDate = StatusState.Positive.firstCheckin(from: startDate)
        let vc = makeViewController(
            persistence: PersistenceDouble(),
            statusStateMachine: StatusStateMachiningDouble(state: .positive(StatusState.Positive(checkinDate: endDate, symptoms: [], startDate: startDate)))
        )
        let navigationController = SynchronousNavigationControllerDouble()
        navigationController.viewControllers = [vc]
        
        vc.adviceTapped()
        
        let adviceVc = try XCTUnwrap(vc.navigationController?.viewControllers.last as? AdviceViewController)
        XCTAssertNotNil(adviceVc.view)
        XCTAssertEqual(adviceVc.link.url, URL(string: "https://faq.covid19.nhs.uk/article/KA-01064/en-us"))
        XCTAssertEqual(adviceVc.detail.text, "The advice below is up-to-date and specific to your situation. Follow this advice until 7 May 2020.")
    }

    func testDoesNotShowsDrawerAfterCheckinIfTemperature() throws{
        try PresentationSpy.withSpy {
            let persistence = PersistenceDouble(statusState: .symptomatic(StatusState.Symptomatic(symptoms: [.cough], startDate: Date(), checkinDate: Date())))
            
            let drawerMailbox = DrawerMailboxingDouble()
            let statusStateMachine = StatusStateMachine(
                persisting: persistence,
                contactEventsUploader: ContactEventsUploaderDouble(),
                drawerMailbox: drawerMailbox,
                notificationCenter: NotificationCenter(),
                userNotificationCenter: UserNotificationCenterDouble()
            )
            
            let drawerPresenter = DrawerPresenterDouble()
            let vc = makeViewController(
                persistence: persistence,
                statusStateMachine: statusStateMachine,
                loadView: true,
                makePresentSynchronous: true,
                drawerPresenter: drawerPresenter,
                drawerMailbox: drawerMailbox
            )
            
            vc.reload()

            let drawer = try XCTUnwrap(drawerPresenter.presented)

            // Manually reset presented since UIKit doesn't do it for us in the test
            drawerPresenter.presented = nil

            let cta = try XCTUnwrap(drawer.callToAction)
            let (_, action) = cta
            action()

            try respondToSymptomQuestion(vc: vc, expectedTitle: "TEMPERATURE_CHECKIN_QUESTION", response: true)
            try respondToSymptomQuestion(vc: vc, expectedTitle: "COUGH_CHECKIN_QUESTION", response: true)
            try respondToSymptomQuestion(vc: vc, expectedTitle: "ANOSMIA_CHECKIN_QUESTION", response: false)

            XCTAssertNil(drawerPresenter.presented)
        }
    }

    func testReloadsAfterClosingDrawer() throws {
        try PresentationSpy.withSpy {
            let checkinDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            let machine = StatusStateMachiningDouble(state:
                .positive(StatusState.Positive(
                    checkinDate: checkinDate, symptoms: [.temperature], startDate: Date()
                ))
            )
            let presenter = DrawerPresenterDouble()
            let mailbox = DrawerMailboxingDouble([.positiveTestResult, .checkin])

            _ = makeViewController(
                statusStateMachine: machine,
                makePresentSynchronous: true,
                drawerPresenter: presenter,
                drawerMailbox: mailbox
            )
            
            var drawer = try XCTUnwrap(presenter.presented)
            drawer.closeTapped()

            drawer = try XCTUnwrap(presenter.presented)
            XCTAssertEqual(drawer.header, "CHECKIN_QUESTIONNAIRE_OVERLAY_HEADER".localized)
        }
    }

    func testListensForNewDrawerMessages() throws {
        let notificationCenter = NotificationCenter()
        let presenter = DrawerPresenterDouble()
        let mailbox = DrawerMailboxingDouble()

        _ = makeViewController(
            notificationCenter: notificationCenter,
            makePresentSynchronous: true,
            drawerPresenter: presenter,
            drawerMailbox: mailbox
        )
        mailbox.messages.append(.unexposed)
        notificationCenter.post(name: DrawerMessage.DrawerMessagePosted, object: nil)

        let drawer = try XCTUnwrap(presenter.presented)
        XCTAssertEqual(drawer.header, "UNEXPOSED_DRAWER_HEADER".localized)
        XCTAssertTrue(mailbox.messages.isEmpty)
    }

    func testUnexposed() throws {
        let presenter = DrawerPresenterDouble()
        let mailbox = DrawerMailboxingDouble([.unexposed])

        _ = makeViewController(drawerPresenter: presenter, drawerMailbox: mailbox)

        let drawer = try XCTUnwrap(presenter.presented)
        XCTAssertEqual(drawer.header, "UNEXPOSED_DRAWER_HEADER".localized)
        XCTAssertTrue(mailbox.messages.isEmpty)
    }

    func testSymptomsButNotSymptomatic() throws {
        let presenter = DrawerPresenterDouble()
        let mailbox = DrawerMailboxingDouble([.symptomsButNotSymptomatic])

        _ = makeViewController(drawerPresenter: presenter, drawerMailbox: mailbox)

        let drawer = try XCTUnwrap(presenter.presented)
        XCTAssertEqual(drawer.header, "HAVE_SYMPTOMS_BUT_DONT_ISOLATE_DRAWER_HEADER".localized)
        XCTAssertTrue(mailbox.messages.isEmpty)
    }

    func testTestResultPositive() throws {
        let presenter = DrawerPresenterDouble()
        let mailbox = DrawerMailboxingDouble([.positiveTestResult])

        _ = makeViewController(drawerPresenter: presenter, drawerMailbox: mailbox)

        let drawer = try XCTUnwrap(presenter.presented)
        XCTAssertEqual(drawer.header, "TEST_UPDATE_DRAW_POSITIVE_HEADER".localized)
        XCTAssertTrue(mailbox.messages.isEmpty)
    }

    func testTestResultNegative() throws {
        let presenter = DrawerPresenterDouble()
        let mailbox = DrawerMailboxingDouble([.negativeTestResult])

        _ = makeViewController(drawerPresenter: presenter, drawerMailbox: mailbox)

        let drawer = try XCTUnwrap(presenter.presented)
        XCTAssertEqual(drawer.header, "NEGATIVE_RESULT_QUESTIONNAIRE_OVERLAY_HEADER".localized)
        XCTAssertTrue(mailbox.messages.isEmpty)
    }

    func testTestResultUnclear() throws {
        let presenter = DrawerPresenterDouble()
        let mailbox = DrawerMailboxingDouble([.unclearTestResult])

        _ = makeViewController(drawerPresenter: presenter, drawerMailbox: mailbox)

        let drawer = try XCTUnwrap(presenter.presented)
        XCTAssertEqual(drawer.header, "TEST_UPDATE_DRAW_INVALID_HEADER".localized)
        XCTAssertTrue(mailbox.messages.isEmpty)
    }
    
    private func respondToSymptomQuestion(
        vc: StatusViewController,
        expectedTitle: String,
        response: Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let promptVc = try XCTUnwrap(vc.navigationController?.topViewController as? QuestionSymptomsViewController, file: file, line: line)
        XCTAssertNotNil(promptVc.view)
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
        drawerPresenter: DrawerPresenter = DrawerPresenterDouble(),
        drawerMailbox: DrawerMailboxing = DrawerMailboxingDouble()
    ) -> StatusViewController {
        let vc = StatusViewController.instantiate()
        vc.inject(
            statusStateMachine: statusStateMachine,
            persistence: persistence,
            linkingIdManager: LinkingIdManagerDouble(),
            registrationService: registrationService,
            notificationCenter: notificationCenter,
            drawerPresenter: drawerPresenter,
            drawerMailbox: drawerMailbox,
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
    var presented: DrawerViewController?
    
    func present(drawer: DrawerViewController, inNavigationController: UINavigationController, usingTransitioningDelegate: UIViewControllerTransitioningDelegate) {
        presented = drawer
    }
}
