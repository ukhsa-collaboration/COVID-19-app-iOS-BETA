//
//  NotificationManagerTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

import XCTest
@testable import CoLocate

class NotificationManagerTests: XCTestCase {
    override func setUp() {
        super.setUp()

        FirebaseAppDouble.configureCalled = false
    }

    func testConfigure() {
        let notificationManager = NotificationManager(
            uiQueue: .main,
            firebase: FirebaseAppDouble.self,
            userNotificationCenter: NotificationCenterDouble()
        )

        notificationManager.configure()

        XCTAssertTrue(FirebaseAppDouble.configureCalled)
    }

    func testRequestAuthorization_success() {
        let notificationCenterDouble = NotificationCenterDouble()
        let notificationManager = NotificationManager(
            uiQueue: DispatchQueue.test,
            firebase: FirebaseAppDouble.self,
            userNotificationCenter: notificationCenterDouble
        )

        let applicationDouble = ApplicationDouble()
        var granted: Bool?
        var error: Error?
        notificationManager.requestAuthorization(application: applicationDouble) { result in
            switch result {
            case .success(let g): granted = g
            case .failure(let e): error = e
            }
        }

        notificationCenterDouble.completionHandler!(true, nil)
        DispatchQueue.test.flush()

        XCTAssertTrue(applicationDouble.registeredForRemoteNotifications)
        XCTAssertTrue(granted!)
        XCTAssertNil(error)
    }
}

class ApplicationDouble: Application {
    var registeredForRemoteNotifications = false
    func registerForRemoteNotifications() {
        registeredForRemoteNotifications = true
    }
}

class FirebaseAppDouble: TestableFirebaseApp {
    static var configureCalled = false
    static func configure() {
        configureCalled = true
    }
}

class NotificationCenterDouble: UserNotificationCenter {

    var delegate: UNUserNotificationCenterDelegate?

    var options: UNAuthorizationOptions?
    var completionHandler: ((Bool, Error?) -> Void)?
    func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping (Bool, Error?) -> Void) {
        self.options = options
        self.completionHandler = completionHandler
    }

}
