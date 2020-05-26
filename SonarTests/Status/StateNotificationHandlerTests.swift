//
//  StateNotificationHandlerTests.swift
//  SonarTests
//
//  Created by NHSX on 4/28/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class StateNotificationHandlerTests: XCTestCase {

    var exposureNotificationHandler: ExposedNotificationHandler!
    var statusStateMachine: StatusStateMachiningDouble!

    override func setUp() {
        statusStateMachine = StatusStateMachiningDouble(state: .ok(StatusState.Ok()))
        exposureNotificationHandler = ExposedNotificationHandler(statusStateMachine: statusStateMachine)
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

        XCTAssertFalse(statusStateMachine.exposedCalled)
    }

    func testPotentialStatus() {
        var fetchResult: UIBackgroundFetchResult?

        exposureNotificationHandler.handle(userInfo: ["status": "Potential"]) { fetchResult = $0 }

        XCTAssertTrue(statusStateMachine.exposedCalled)

        XCTAssertEqual(fetchResult, .newData)
    }
}
