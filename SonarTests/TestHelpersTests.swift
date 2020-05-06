//
//  TestHelpersTests.swift
//  SonarTests
//
//  Created by NHSX on 30.04.20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest

class TestHelpersTests: XCTestCase {

    func testFollowingMidnightUTC() throws {
        let middayAprilFoolsComps = DateComponents(calendar: Calendar(identifier: .gregorian), timeZone: TimeZone(identifier: "Europe/Berlin"), year: 2020, month: 4, day: 1, hour: 12, minute: 0, second: 0)
        let middayAprilFools = middayAprilFoolsComps.date! // CEST aka UTC+2; daylight saving cut in on March 29
        
        let beginningApril2Comps = DateComponents(calendar: Calendar(identifier: .gregorian), timeZone: TimeZone(identifier: "UTC"), year: 2020, month: 4, day: 2, hour: 0, minute: 0, second: 0)
        let beginningOfApril2 = beginningApril2Comps.date!
        
        XCTAssertEqual(middayAprilFools.followingMidnightUTC, beginningOfApril2)
    }

}
