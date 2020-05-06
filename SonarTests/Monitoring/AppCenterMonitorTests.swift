//
//  AppCenterMonitorTests.swift
//  SonarTests
//
//  Created by NHSX on 01/05/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class AppCenterMonitorTests: XCTestCase {
    
    private var reporter: AppCenterAnalyticsReportingDouble!
    private var monitor: AppCenterMonitor!
    
    override func setUp() {
        super.setUp()
        
        reporter = AppCenterAnalyticsReportingDouble()
        monitor = AppCenterMonitor(reporter: reporter)
    }
    
    func testPartialPostcodeProvided() {
        test(.partialPostcodeProvided, isTrackedWithName: "Partial postcode provided")
    }
    
    func testOnboardingCompleted() {
        test(.onboardingCompleted, isTrackedWithName: "Onboarding completed")
    }
    
    func testRegistrationSucceeded() {
        test(.registrationSucceeded, isTrackedWithName: "Registration succeeded")
    }
    
    func testRegistrationFailure_waitingForFCMTokenTimedOut() {
        test(.registrationFailed(reason: .waitingForFCMTokenTimedOut),
             isTrackedWithName: "Registration failed",
             properties: ["Reason": "No FCM token"]
        )
    }
    
    func testRegistrationFailure_registrationCallFailed() {
        test(.registrationFailed(reason: .registrationCallFailed(statusCode: nil)),
             isTrackedWithName: "Registration failed",
             properties: ["Reason": "Registration call failed"]
        )
    }
    
    func testRegistrationFailure_registrationCallFailedWithStatusCode() {
        test(.registrationFailed(reason: .registrationCallFailed(statusCode: 400)),
             isTrackedWithName: "Registration failed",
             properties: ["Reason": "Registration call failed", "Status code": "400"]
        )
    }
    
    func testRegistrationFailure_waitingForActivationNotificationTimedOut() {
        test(.registrationFailed(reason: .waitingForActivationNotificationTimedOut),
             isTrackedWithName: "Registration failed",
             properties: ["Reason": "Activation notification not received"]
        )
    }
    
    func testRegistrationFailure_activationCallFailed() {
        test(.registrationFailed(reason: .activationCallFailed(statusCode: nil)),
             isTrackedWithName: "Registration failed",
             properties: ["Reason": "Activation call failed"]
        )
    }
    
    func testRegistrationFailure_activationCallFailedWithStatusCode() {
        test(.registrationFailed(reason: .activationCallFailed(statusCode: 400)),
             isTrackedWithName: "Registration failed",
             properties: ["Reason": "Activation call failed", "Status code": "400"]
        )
    }
    
    func testCollectedContactEvents() {
        test(
            .collectedContactEvents(yesterday: 72, all: 202),
            isTrackedWithName: "Collected contact events",
            properties: [
                "Yesterday": "72",
                "All": "202",
            ]
        )
    }
    
    func test(
        _ event: AppEvent,
        isTrackedWithName name: String,
        properties: [String : String]? = nil,
        file: StaticString = #file, line: UInt = #line) {
        monitor.report(event)
        
        continueAfterFailure = false
        XCTAssertEqual(reporter.trackedEvents.count, 1, "Expected one tracked event for \(event)", file: file, line: line)
        
        let trackedEvent = reporter.trackedEvents.first!
        XCTAssertEqual(trackedEvent.eventName, name, "Incorrect name for \(event)", file: file, line: line)
        XCTAssertEqual(trackedEvent.properties, properties, "Incorrect properties for \(event)", file: file, line: line)
    }
    
}
