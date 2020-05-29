//
//  ExposedNotificationHandlerTests.swift
//  SonarTests
//
//  Created by NHSX on 4/28/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class ExposedNotificationHandlerTests: XCTestCase {

    var exposureNotificationHandler: ExposedNotificationHandler!
    var statusStateMachine: StatusStateMachiningDouble!
    var currentDate: Date!

    let dateFormatter = ISO8601DateFormatter()

    override func setUp() {
        currentDate = Date()
        statusStateMachine = StatusStateMachiningDouble()
        exposureNotificationHandler = ExposedNotificationHandler(
            statusStateMachine: statusStateMachine,
            dateProvider: { self.currentDate }
        )
    }

    func testNotPotential() {
        var fetchResult: UIBackgroundFetchResult?

        exposureNotificationHandler.handle(userInfo: [:]) { fetchResult = $0 }
        XCTAssertEqual(fetchResult, .noData)
        fetchResult = nil

        exposureNotificationHandler.handle(userInfo: ["status": 10]) { fetchResult = $0 }
        XCTAssertEqual(fetchResult, .noData)
        fetchResult = nil

        exposureNotificationHandler.handle(userInfo: ["status": "foo"]) { fetchResult = $0 }
        XCTAssertEqual(fetchResult, .noData)

        XCTAssertNil(statusStateMachine.exposedDate)
    }

    func testPotentialStatus() {
        var fetchResult: UIBackgroundFetchResult?

        let exposedDate = "2020-01-01T00:00:00Z"
        let userInfo = ["status": "Potential", "mostRecentProximityEventDate": exposedDate]
        exposureNotificationHandler.handle(userInfo: userInfo) { fetchResult = $0 }

        XCTAssertEqual(statusStateMachine.exposedDate, dateFormatter.date(from: exposedDate))
        XCTAssertEqual(fetchResult, .newData)
    }

    func testPotentialStatusBackCompat() {
        currentDate = Date()

        var fetchResult: UIBackgroundFetchResult?

        let userInfo = ["status": "Potential"]
        exposureNotificationHandler.handle(userInfo: userInfo) { fetchResult = $0 }

        XCTAssertEqual(statusStateMachine.exposedDate, currentDate)
        XCTAssertEqual(fetchResult, .newData)
    }

}
