//
//  StatusNotificationHandlerTests.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class StatusNotificationHandlerTests: XCTestCase {

    var handler: StatusNotificationHandler!
    var persisting: PersistenceDouble!
    var userNotificationCenter: UserNotificationCenterDouble!
    var currentDate: Date!

    var receivedNotification: Bool!

    override func setUp() {
        persisting = PersistenceDouble()
        userNotificationCenter = UserNotificationCenterDouble()
        let notificationCenter = NotificationCenter()
        currentDate = Date()
        handler = StatusNotificationHandler(
            persisting: persisting,
            userNotificationCenter: userNotificationCenter,
            notificationCenter: notificationCenter,
            currentDateProvider: { self.currentDate }
        )

        receivedNotification = false
        notificationCenter.addObserver(forName: PotentiallyExposedNotification, object: nil, queue: nil) { _ in
            self.receivedNotification = true
        }
    }

    func testNotPotential() {
        handler.handle(userInfo: [:])
        handler.handle(userInfo: ["status": 10])
        handler.handle(userInfo: ["status": "foo"])

        XCTAssertNil(persisting.potentiallyExposed)
        XCTAssertNil(userNotificationCenter.request)
        XCTAssertFalse(receivedNotification)
    }

    func testPotentialStatus() {
        handler.handle(userInfo: ["status": "Potential"])

        XCTAssertEqual(persisting.potentiallyExposed, currentDate)
        XCTAssertNotNil(userNotificationCenter.request)
        XCTAssertTrue(receivedNotification)
    }

}
