//
//  RegistrationReminderSchedulerTests.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class RegistrationReminderSchedulerTests: TestCase {
    
    func testSchedulesRecurring24HourNotification() {
        let userNotificationCenter = UserNotificationCenterDouble()
        let scheduler = ConcreteRegistrationReminderScheduler(userNotificationCenter: userNotificationCenter)
        
        scheduler.schedule()
        
        XCTAssertEqual(userNotificationCenter.request?.identifier, "registration.reminder")
        XCTAssertEqual(userNotificationCenter.request?.content.body, "Your registration has failed. Please open the app and select retry to complete your registration.")
        let trigger = userNotificationCenter.request?.trigger as? UNTimeIntervalNotificationTrigger
        XCTAssertEqual(trigger?.timeInterval, 60 * 60 * 24)
        XCTAssertEqual(trigger?.repeats, true)
    }
    
    func testCancelsNotification() {
        let userNotificationCenter = UserNotificationCenterDouble()
        let scheduler = ConcreteRegistrationReminderScheduler(userNotificationCenter: userNotificationCenter)
        
        scheduler.cancel()

        XCTAssertEqual(userNotificationCenter.removedIdentifiers, ["registration.reminder"])
    }
}
