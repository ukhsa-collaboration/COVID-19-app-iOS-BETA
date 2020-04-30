//
//  LocalNotificationTests.swift
//  SonarTests
//
//  Created on 22/04/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class LocalNotificationTests: XCTestCase {
    func testCanEstablishCorrectDate() {
        let localNotificationScheduler = LocalNotifcationScheduler(userNotificationCenter: UserNotificationCenterDouble())
        let date = Date(timeIntervalSince1970: 0)
        let components = localNotificationScheduler.getDateAfter(days: 8, from: date)
        XCTAssertEqual(components, DateComponents(year: 1970, month: 1, day: 9, hour: 7))
    }
}
