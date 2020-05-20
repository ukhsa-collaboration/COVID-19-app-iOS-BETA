//
//  RegistrationReminderSchedulerTests.swift
//  SonarTests
//
//  Created by NHSX on 4/24/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class RegistrationReminderSchedulerTests: TestCase {
    
    func testSchedule() {
        let userNotificationCenter = UserNotificationCenterDouble()
        let scheduler = ConcreteRegistrationReminderScheduler(userNotificationCenter: userNotificationCenter)
        
        scheduler.schedule()
        
        XCTAssertEqual(userNotificationCenter.requests.count, 2)
        XCTAssertEqual(userNotificationCenter.requests[0].identifier, "registration.reminder")
        XCTAssertEqual(userNotificationCenter.requests[0].content.body, "Your registration has failed. Please open the app and select retry to complete your registration.")
        let trigger0 = userNotificationCenter.requests[0].trigger as? UNTimeIntervalNotificationTrigger
        XCTAssertEqual(trigger0?.timeInterval, 60 * 60 * 24)
        XCTAssertEqual(trigger0?.repeats, true)
        
        XCTAssertEqual(userNotificationCenter.requests[1].identifier, "registration.oneTimeReminder")
        XCTAssertEqual(userNotificationCenter.requests[1].content.body, "Your registration has failed. Please open the app and select retry to complete your registration.")
        let trigger1 = userNotificationCenter.requests[1].trigger as? UNTimeIntervalNotificationTrigger
        XCTAssertEqual(trigger1?.timeInterval, 60 * 60)
        XCTAssertEqual(trigger1?.repeats, false)

    }

    func testCancel() {
        let userNotificationCenter = UserNotificationCenterDouble()
        let scheduler = ConcreteRegistrationReminderScheduler(userNotificationCenter: userNotificationCenter)
        
        scheduler.cancel()

        XCTAssertEqual(userNotificationCenter.removedIdentifiers, ["registration.reminder", "registration.oneTimeReminder"])
    }

}
