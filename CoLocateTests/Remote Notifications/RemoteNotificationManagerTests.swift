//
//  RemoteNotificationManagerTests.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

import XCTest
import Firebase
@testable import Sonar

class RemoteNotificationManagerTests: TestCase {

    override func setUp() {
        super.setUp()

        FirebaseAppDouble.configureCalled = false
    }

    func testConfigure() {
        let messaging = MessagingDouble()
        let notificationManager = ConcreteRemoteNotificationManager(
            firebase: FirebaseAppDouble.self,
            messagingFactory: { messaging },
            userNotificationCenter: UserNotificationCenterDouble(),
            dispatcher: RemoteNotificationDispatcher(notificationCenter: NotificationCenter(), userNotificationCenter: UserNotificationCenterDouble())
        )

        notificationManager.configure()

        XCTAssertTrue(FirebaseAppDouble.configureCalled)
    }
    
    func testPushTokenHandling() {
        let messaging = MessagingDouble()
        let notificationCenter = NotificationCenter()
        let notificationManager = ConcreteRemoteNotificationManager(
            firebase: FirebaseAppDouble.self,
            messagingFactory: { messaging },
            userNotificationCenter: UserNotificationCenterDouble(),
            dispatcher: RemoteNotificationDispatcher(notificationCenter: notificationCenter, userNotificationCenter: UserNotificationCenterDouble())
        )

        var receivedPushToken: String?
        notificationCenter.addObserver(forName: PushTokenReceivedNotification, object: nil, queue: nil) { notification in
            receivedPushToken = notification.object as? String
        }

        notificationManager.configure()
        // Ugh, can't find a way to not pass a real Messaging here. Should be ok as long as the actual delegate method doesn't use it.
        messaging.delegate!.messaging?(Messaging.messaging(), didReceiveRegistrationToken: "12345")
        XCTAssertEqual("12345", notificationManager.pushToken)
        XCTAssertEqual("12345", receivedPushToken)
    }

    func testRequestAuthorization_success() {
        let notificationCenterDouble = UserNotificationCenterDouble()
        let notificationManager = ConcreteRemoteNotificationManager(
            firebase: FirebaseAppDouble.self,
            messagingFactory: { MessagingDouble() },
            userNotificationCenter: notificationCenterDouble,
            dispatcher: RemoteNotificationDispatcher(notificationCenter: NotificationCenter(), userNotificationCenter: UserNotificationCenterDouble())
        )

        var granted: Bool?
        var error: Error?
        notificationManager.requestAuthorization { result in
            switch result {
            case .success(let g): granted = g
            case .failure(let e): error = e
            }
        }

        notificationCenterDouble.requestAuthCompletionHandler!(true, nil)
        DispatchQueue.test.flush()

        XCTAssertTrue(granted!)
        XCTAssertNil(error)
    }
        
    func testHandleNotification_dispatchesPotentialDiagnosis() {
        let notificationManager = ConcreteRemoteNotificationManager(
            firebase: FirebaseAppDouble.self,
            messagingFactory: { MessagingDouble() },
            userNotificationCenter: UserNotificationCenterDouble(),
            dispatcher: RemoteNotificationDispatcher(notificationCenter: NotificationCenter(), userNotificationCenter: UserNotificationCenterDouble())
        )
        
        var called = false
        notificationManager.dispatcher.registerHandler(forType: .potentialDiagnosis) { (userInfo, completionHandler) in
            called = true
            completionHandler(.newData)
        }
        
        notificationManager.handleNotification(userInfo: ["status" : "Potential"], completionHandler: { _ in })
        
        XCTAssertTrue(called)
    }

    func testHandleNotification_sendsLocalNotificationWithPotentialStatus() {
        let userNotificationCenter = UserNotificationCenterDouble()
        let notificationManager = ConcreteRemoteNotificationManager(
            firebase: FirebaseAppDouble.self,
            messagingFactory: { MessagingDouble() },
            userNotificationCenter: userNotificationCenter,
            dispatcher: RemoteNotificationDispatcher(notificationCenter: NotificationCenter(), userNotificationCenter: userNotificationCenter)
        )
        
        notificationManager.dispatcher.registerHandler(forType: .potentialDiagnosis) { (userInfo, completionHandler) in
            completionHandler(.newData)
        }

        notificationManager.handleNotification(userInfo: ["status" : "Potential"]) {_ in }

        XCTAssertNotNil(userNotificationCenter.request)
    }
    
    func testHandleNotification_doesNotDispatchOtherDiagnosis() {
        let notificationManager = ConcreteRemoteNotificationManager(
            firebase: FirebaseAppDouble.self,
            messagingFactory: { MessagingDouble() },
            userNotificationCenter: UserNotificationCenterDouble(),
            dispatcher: RemoteNotificationDispatcher(notificationCenter: NotificationCenter(), userNotificationCenter: UserNotificationCenterDouble())
        )
        
        var called = false
        notificationManager.dispatcher.registerHandler(forType: .potentialDiagnosis) { (userInfo, completionHandler) in
            called = true
            completionHandler(.newData)
        }
        
        notificationManager.handleNotification(userInfo: ["status" : "infected"]) {_ in }
        
        XCTAssertFalse(called)
    }

    func testHandleNotification_doesNotSendLocalNotificationWhenStatusIsNotPotential() {
        let notificationCenterDouble = UserNotificationCenterDouble()
        let notificationManager = ConcreteRemoteNotificationManager(
            firebase: FirebaseAppDouble.self,
            messagingFactory: { MessagingDouble() },
            userNotificationCenter: notificationCenterDouble,
            dispatcher: RemoteNotificationDispatcher(notificationCenter: NotificationCenter(), userNotificationCenter: UserNotificationCenterDouble())
        )

        notificationManager.handleNotification(userInfo: ["status" : "infected"]) {_ in }

        XCTAssertNil(notificationCenterDouble.request)
    }
    
    func testHandleNotificaton_routesRegistrationAccessTokenNotifications() {
        let notificationManager = ConcreteRemoteNotificationManager(
            firebase: FirebaseAppDouble.self,
            messagingFactory: { MessagingDouble() },
            userNotificationCenter: UserNotificationCenterDouble(),
            dispatcher: RemoteNotificationDispatcher(notificationCenter: NotificationCenter(), userNotificationCenter: UserNotificationCenterDouble())
        )
        var callersCompletionCalled = false
        var statusChangeHandlerCalled = false
        var receivedUserInfo: [AnyHashable : Any]? = nil
        
        notificationManager.registerHandler(forType: RemoteNotificationType.registrationActivationCode) { userInfo, completionHandler in
            receivedUserInfo = userInfo
            completionHandler(.newData)
        }
        
        notificationManager.registerHandler(forType: .potentialDiagnosis) { userInfo, completionHandler in
            statusChangeHandlerCalled = true
        }

        notificationManager.handleNotification(userInfo: ["activationCode" : "foo"]) { fetchResult in
            callersCompletionCalled = true
        }
        
        XCTAssertEqual(receivedUserInfo?["activationCode"] as? String, "foo")
        XCTAssertTrue(callersCompletionCalled)
        XCTAssertFalse(statusChangeHandlerCalled)
    }
    
    func testHandlesNotification_doesNotCrashOnUnknownNotification() {
        let notificationManager = ConcreteRemoteNotificationManager(
            firebase: FirebaseAppDouble.self,
            messagingFactory: { MessagingDouble() },
            userNotificationCenter: UserNotificationCenterDouble(),
            dispatcher: RemoteNotificationDispatcher(notificationCenter: NotificationCenter(), userNotificationCenter: UserNotificationCenterDouble())
        )
        
        notificationManager.handleNotification(userInfo: ["something": "unexpected"]) { fetchResult in }
    }

    func testHandleNotification_foreGroundedLocalNotification() {
        let notificationCenterDouble = UserNotificationCenterDouble()
        let notificationManager = ConcreteRemoteNotificationManager(
            firebase: FirebaseAppDouble.self,
            messagingFactory: { MessagingDouble() },
            userNotificationCenter: notificationCenterDouble,
            dispatcher: RemoteNotificationDispatcher(notificationCenter: NotificationCenter(), userNotificationCenter: UserNotificationCenterDouble())
        )

        notificationManager.handleNotification(userInfo: [:]) {_ in }

        XCTAssertNil(notificationCenterDouble.request)
    }
}

private class FirebaseAppDouble: TestableFirebaseApp {
    static var configureCalled = false
    static func configure() {
        configureCalled = true
    }
}

private class MessagingDouble: TestableMessaging {
    weak var delegate: MessagingDelegate?
}
