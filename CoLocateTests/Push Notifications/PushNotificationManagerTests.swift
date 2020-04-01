//
//  PushNotificationManagerTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

import XCTest
import Firebase
@testable import CoLocate

class PushNotificationManagerTests: TestCase {

    override func setUp() {
        super.setUp()

        FirebaseAppDouble.configureCalled = false
    }

    func testConfigure() {
        let messaging = MessagingDouble()
        let notificationManager = ConcretePushNotificationManager(
            firebase: FirebaseAppDouble.self,
            messagingFactory: { messaging },
            userNotificationCenter: UserNotificationCenterDouble(),
            notificationCenter: NotificationCenter(),
            persistence: Persistence()
        )

        notificationManager.configure()

        XCTAssertTrue(FirebaseAppDouble.configureCalled)
    }
    
    func testPushTokenHandling() {
        let messaging = MessagingDouble()
        let notificationCenter = NotificationCenter()
        let notificationManager = ConcretePushNotificationManager(
            firebase: FirebaseAppDouble.self,
            messagingFactory: { messaging },
            userNotificationCenter: UserNotificationCenterDouble(),
            notificationCenter: notificationCenter,
            persistence: Persistence()
        )

        notificationManager.configure()
        // Ugh, can't find a way to not pass a real Messaging here. Should be ok as long as the actual delegate method doesn't use it.
        messaging.delegate!.messaging?(Messaging.messaging(), didReceiveRegistrationToken: "12345")
        XCTAssertEqual("12345", notificationManager.pushToken)
    }

    func testRequestAuthorization_success() {
        let notificationCenterDouble = UserNotificationCenterDouble()
        let notificationManager = ConcretePushNotificationManager(
            firebase: FirebaseAppDouble.self,
            messagingFactory: { MessagingDouble() },
            userNotificationCenter: notificationCenterDouble,
            notificationCenter: NotificationCenter(),
            persistence: Persistence()
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
        
    func testHandleNotification_savesPotentialDiagnosis() {
        let persistence = Persistence()
        let notificationManager = ConcretePushNotificationManager(
            firebase: FirebaseAppDouble.self,
            messagingFactory: { MessagingDouble() },
            userNotificationCenter: UserNotificationCenterDouble(),
            notificationCenter: NotificationCenter(),
            persistence: persistence
        )
        
        notificationManager.handleNotification(userInfo: ["status" : "Potential"], completionHandler: { _ in })
        
        XCTAssertEqual(persistence.diagnosis, .potential)
    }

    func testHandleNotification_sendsLocalNotificationWithPotentialStatus() {
        let persistence = Persistence()
        let notificationCenterDouble = UserNotificationCenterDouble()
        let notificationManager = ConcretePushNotificationManager(
            firebase: FirebaseAppDouble.self,
            messagingFactory: { MessagingDouble() },
            userNotificationCenter: notificationCenterDouble,
            notificationCenter: NotificationCenter(),
            persistence: persistence
        )

        notificationManager.handleNotification(userInfo: ["status" : "Potential"]) {_ in }

        XCTAssertNotNil(notificationCenterDouble.request)
    }
    
    func testHandleNotification_doesNotSaveOtherDiagnosis() {
        let persistence = Persistence()
        let notificationManager = ConcretePushNotificationManager(
            firebase: FirebaseAppDouble.self,
            messagingFactory: { MessagingDouble() },
            userNotificationCenter: UserNotificationCenterDouble(),
            notificationCenter: NotificationCenter(),
            persistence: persistence
        )
        
        notificationManager.handleNotification(userInfo: ["status" : "infected"]) {_ in }
        
        XCTAssertEqual(persistence.diagnosis, .unknown)
    }

    func testHandleNotification_doesNotSendLocalNotificationWhenStatusIsNotPotential() {
        let persistence = Persistence()
        let notificationCenterDouble = UserNotificationCenterDouble()
        let notificationManager = ConcretePushNotificationManager(
            firebase: FirebaseAppDouble.self,
            messagingFactory: { MessagingDouble() },
            userNotificationCenter: notificationCenterDouble,
            notificationCenter: NotificationCenter(),
            persistence: persistence
        )

        notificationManager.handleNotification(userInfo: ["status" : "infected"]) {_ in }

        XCTAssertNil(notificationCenterDouble.request)
    }
    
    func testHandleNotificaton_routesRegistrationAccessTokenNotifications() {
        let notificationManager = ConcretePushNotificationManager(
            firebase: FirebaseAppDouble.self,
            messagingFactory: { MessagingDouble() },
            userNotificationCenter: UserNotificationCenterDouble(),
            notificationCenter: NotificationCenter(),
            persistence: Persistence()
        )
        var callersCompletionCalled = false
        var statusChangeHandlerCalled = false
        var receivedUserInfo: [AnyHashable : Any]? = nil
        
        notificationManager.registerHandler(forType: PushNotificationType.registrationActivationCode) { userInfo, completionHandler in
            receivedUserInfo = userInfo
            completionHandler(.newData)
        }
        
        notificationManager.registerHandler(forType: PushNotificationType.statusChange) { userInfo, completionHandler in
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
        let notificationManager = ConcretePushNotificationManager(
            firebase: FirebaseAppDouble.self,
            messagingFactory: { MessagingDouble() },
            userNotificationCenter: UserNotificationCenterDouble(),
            notificationCenter: NotificationCenter(),
            persistence: Persistence()
        )
        
        notificationManager.handleNotification(userInfo: ["something": "unexpected"]) { fetchResult in }
    }

    func testHandleNotification_foreGroundedLocalNotification() {
        let persistence = Persistence()
        let notificationCenterDouble = UserNotificationCenterDouble()
        let notificationManager = ConcretePushNotificationManager(
            firebase: FirebaseAppDouble.self,
            messagingFactory: { MessagingDouble() },
            userNotificationCenter: notificationCenterDouble,
            notificationCenter: NotificationCenter(),
            persistence: persistence
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

private class UserNotificationCenterDouble: UserNotificationCenter {

    weak var delegate: UNUserNotificationCenterDelegate?

    var options: UNAuthorizationOptions?
    var requestAuthCompletionHandler: ((Bool, Error?) -> Void)?
    func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping (Bool, Error?) -> Void) {
        self.options = options
        self.requestAuthCompletionHandler = completionHandler
    }

    var request: UNNotificationRequest?
    var addCompletionHandler: ((Error?) -> Void)?
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?) {
        self.request = request
        self.addCompletionHandler = completionHandler
    }

}
