//
//  NotificationsPromptViewControllerTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class NotificationsPromptViewControllerTests: XCTestCase {

    func test_requests_notifications_and_advances_to_next_screen() {
        let storyboard = UIStoryboard.init(name: "Notifications", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "NotificationsPromptViewController") as! NotificationsPromptViewController
        let pushNotificationsRequester = PushNotificationRequesterDouble()
        let uiQueue = DispatchQueue.test

        vc.pushNotificationsRequester = pushNotificationsRequester
        vc.uiQueue = uiQueue

        XCTAssertNotNil(vc.view)

        vc.didTapContinue(vc.continueButton!)
        XCTAssertTrue(pushNotificationsRequester.didRequestNotifications)

        pushNotificationsRequester.completion?(.success(true))
        uiQueue.flush()

        XCTAssertTrue(pushNotificationsRequester.didAdvanceAfterPushNotifications)
    }

    func test_does_not_advance_if_notifications_not_granted() {
        let storyboard = UIStoryboard.init(name: "Notifications", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "NotificationsPromptViewController") as! NotificationsPromptViewController
        let pushNotificationsRequester = PushNotificationRequesterDouble()
        let uiQueue = DispatchQueue.test

        vc.pushNotificationsRequester = pushNotificationsRequester
        vc.uiQueue = uiQueue

        XCTAssertNotNil(vc.view)

        vc.didTapContinue(vc.continueButton!)
        XCTAssertTrue(pushNotificationsRequester.didRequestNotifications)

        pushNotificationsRequester.completion?(.success(false))
        uiQueue.flush()

        XCTAssertFalse(pushNotificationsRequester.didAdvanceAfterPushNotifications)
    }
}

class PushNotificationRequesterDouble: PushNotificationRequester {

    var didRequestNotifications = false
    var didAdvanceAfterPushNotifications = false
    var completion: ((Result<Bool, Error>) -> Void)?

    func requestPushNotifications(completion: @escaping (Result<Bool, Error>) -> Void) {
        self.completion = completion
        didRequestNotifications = true
    }

    func advanceAfterPushNotifications() {
        guard didRequestNotifications else { return }

        didAdvanceAfterPushNotifications = true
    }
}
