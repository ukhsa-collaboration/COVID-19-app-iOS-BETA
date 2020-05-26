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
    func testInvalid() {
        let statusStateMachine = StatusStateMachiningDouble(state: .ok(StatusState.Ok()))
        let testResultNotificationHandler = TestResultNotificationHandler(statusStateMachine: statusStateMachine)

        let date = Date(timeIntervalSinceReferenceDate: TimeInterval(Int(4999)))
        let testTimestamp = ISO8601DateFormatter().string(from: date)
        
        var fetchResult: UIBackgroundFetchResult?
        testResultNotificationHandler.handle(userInfo: ["result": "INVALID", "testTimestamp": testTimestamp]) { fetchResult = $0 }
        let expectedTestResult = TestResult(result: .unclear, testTimestamp: date, type: nil, acknowledgementUrl: nil)
        XCTAssertEqual(statusStateMachine.receivedTestResult, expectedTestResult)
        XCTAssertEqual(fetchResult, .newData)
    }
    
    func testPositive() {
        let statusStateMachine = StatusStateMachiningDouble(state: .ok(StatusState.Ok()))
        let testResultNotificationHandler = TestResultNotificationHandler(statusStateMachine: statusStateMachine)

        let date = Date(timeIntervalSinceReferenceDate: TimeInterval(Int(4999)))
        let testTimestamp = ISO8601DateFormatter().string(from: date)
        
        var fetchResult: UIBackgroundFetchResult?
        testResultNotificationHandler.handle(userInfo: ["result": "POSITIVE", "testTimestamp": testTimestamp]) { fetchResult = $0 }
        let expectedTestResult = TestResult(result: .positive, testTimestamp: date, type: nil, acknowledgementUrl: nil)
        XCTAssertEqual(statusStateMachine.receivedTestResult, expectedTestResult)
        XCTAssertEqual(fetchResult, .newData)
    }
    
    func testNegative() {
        let statusStateMachine = StatusStateMachiningDouble(state: .ok(StatusState.Ok()))
        let testResultNotificationHandler = TestResultNotificationHandler(statusStateMachine: statusStateMachine)

        let date = Date(timeIntervalSinceReferenceDate: TimeInterval(Int(4999)))
        let testTimestamp = ISO8601DateFormatter().string(from: date)
        
        var fetchResult: UIBackgroundFetchResult?
        testResultNotificationHandler.handle(userInfo: ["result": "NEGATIVE", "testTimestamp": testTimestamp]) { fetchResult = $0 }
        let expectedTestResult = TestResult(result: .negative, testTimestamp: date, type: nil, acknowledgementUrl: nil)
        XCTAssertEqual(statusStateMachine.receivedTestResult, expectedTestResult)
        XCTAssertEqual(fetchResult, .newData)
    }
    
}
