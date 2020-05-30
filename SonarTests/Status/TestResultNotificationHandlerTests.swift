//
//  TestResultNotificationHandlerTests.swift
//  SonarTests
//
//  Created by NHSX on 5/26/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class TestResultNotificationHandlerTests: XCTestCase {
    func testInvalid() throws {
        let statusStateMachine = StatusStateMachiningDouble(state: .ok(StatusState.Ok()))
        let userNotificationCenter = UserNotificationCenterDouble()
        let testResultNotificationHandler = TestResultNotificationHandler(
            statusStateMachine: statusStateMachine,
            userNotificationCenter: userNotificationCenter
        )

        let date = Date(timeIntervalSinceReferenceDate: TimeInterval(Int(4999)))
        let testTimestamp = ISO8601DateFormatter().string(from: date)
        
        var fetchResult: UIBackgroundFetchResult?
        testResultNotificationHandler.handle(userInfo: ["result": "INVALID", "testTimestamp": testTimestamp]) { fetchResult = $0 }
        let expectedTestResult = TestResult(result: .unclear, testTimestamp: date, type: nil, acknowledgementUrl: nil)
        XCTAssertEqual(statusStateMachine.receivedTestResult, expectedTestResult)
        try verifyNotification(userNotificationCenter: userNotificationCenter)
        XCTAssertEqual(fetchResult, .newData)
    }
    
    func testPositive() throws {
        let statusStateMachine = StatusStateMachiningDouble(state: .ok(StatusState.Ok()))
        let userNotificationCenter = UserNotificationCenterDouble()
        let testResultNotificationHandler = TestResultNotificationHandler(
            statusStateMachine: statusStateMachine,
            userNotificationCenter: userNotificationCenter
        )

        let date = Date(timeIntervalSinceReferenceDate: TimeInterval(Int(4999)))
        let testTimestamp = ISO8601DateFormatter().string(from: date)
        
        var fetchResult: UIBackgroundFetchResult?
        testResultNotificationHandler.handle(userInfo: ["result": "POSITIVE", "testTimestamp": testTimestamp]) { fetchResult = $0 }
        let expectedTestResult = TestResult(result: .positive, testTimestamp: date, type: nil, acknowledgementUrl: nil)
        XCTAssertEqual(statusStateMachine.receivedTestResult, expectedTestResult)
        try verifyNotification(userNotificationCenter: userNotificationCenter)
        XCTAssertEqual(fetchResult, .newData)
    }
    
    func testNegative() throws {
        let statusStateMachine = StatusStateMachiningDouble(state: .ok(StatusState.Ok()))
        let userNotificationCenter = UserNotificationCenterDouble()
        let testResultNotificationHandler = TestResultNotificationHandler(
            statusStateMachine: statusStateMachine,
            userNotificationCenter: userNotificationCenter
        )

        let date = Date(timeIntervalSinceReferenceDate: TimeInterval(Int(4999)))
        let testTimestamp = ISO8601DateFormatter().string(from: date)
        
        var fetchResult: UIBackgroundFetchResult?
        testResultNotificationHandler.handle(userInfo: ["result": "NEGATIVE", "testTimestamp": testTimestamp]) { fetchResult = $0 }
        let expectedTestResult = TestResult(result: .negative, testTimestamp: date, type: nil, acknowledgementUrl: nil)
        XCTAssertEqual(statusStateMachine.receivedTestResult, expectedTestResult)
        try verifyNotification(userNotificationCenter: userNotificationCenter)
        XCTAssertEqual(fetchResult, .newData)
    }

    private func verifyNotification(
        userNotificationCenter: UserNotificationCenterDouble,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let notification = try XCTUnwrap(userNotificationCenter.requests.first, file: file, line: line)
        XCTAssertEqual(notification.identifier, "testResult.arrived", file: file, line: line)
        XCTAssertEqual(notification.content.body, "Your test result has arrived. Please open the app to learn what to do next. You have been sent an email or text with more information.", file: file, line: line)
        let trigger = try XCTUnwrap(notification.trigger as? UNTimeIntervalNotificationTrigger, file: file, line: line)
        XCTAssertEqual(trigger.timeInterval, 10, file: file, line: line)
        XCTAssertFalse(trigger.repeats, file: file, line: line)
    }
}
