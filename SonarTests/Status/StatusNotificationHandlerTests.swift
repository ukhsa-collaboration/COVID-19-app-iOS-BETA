//
//  StatusNotificationHandlerTests.swift
//  SonarTests
//
//  Created by NHSX on 4/28/20.
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
        var fetchResult: UIBackgroundFetchResult?

        handler.handle(userInfo: [:]) { fetchResult = $0 }
        XCTAssertEqual(fetchResult, .noData)
        fetchResult = nil

        handler.handle(userInfo: ["status": 10]) { fetchResult = $0 }
        XCTAssertEqual(fetchResult, .noData)
        fetchResult = nil

        handler.handle(userInfo: ["status": "foo"]) { fetchResult = $0 }
        XCTAssertEqual(fetchResult, .noData)

        XCTAssertNil(persisting.potentiallyExposed)
        XCTAssertNil(userNotificationCenter.request)
        XCTAssertFalse(receivedNotification)
    }

    func testPotentialStatus() {
        var fetchResult: UIBackgroundFetchResult?

        handler.handle(userInfo: ["status": "Potential"]) { fetchResult = $0 }

        XCTAssertEqual(persisting.potentiallyExposed, currentDate)
        XCTAssertNotNil(userNotificationCenter.request)
        XCTAssertTrue(receivedNotification)
        XCTAssertEqual(fetchResult, .newData)
    }

}
