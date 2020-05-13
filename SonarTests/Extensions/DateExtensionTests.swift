//
//  TestHelpersTests.swift
//  SonarTests
//
//  Created by NHSX on 30.04.20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class DateExtensionTests: XCTestCase {
    
    var middayAprilFoolsComps: DateComponents!
    var middayAprilFools: Date!
    var beginningOfApril2Comps: DateComponents!
    var beginningOfApril2: Date!
    var middayApril2Comps: DateComponents!
    var middayApril2: Date!
    
    override func setUp() {
        middayAprilFoolsComps = DateComponents(calendar: Calendar(identifier: .gregorian), timeZone: TimeZone(identifier: "Europe/Berlin"), year: 2020, month: 4, day: 1, hour: 12, minute: 0, second: 0)
        middayAprilFools = middayAprilFoolsComps.date! // CEST aka UTC+2; daylight saving cut in on March 29
        
        beginningOfApril2Comps = DateComponents(calendar: Calendar(identifier: .gregorian), timeZone: TimeZone(identifier: "UTC"), year: 2020, month: 4, day: 2, hour: 0, minute: 0, second: 0)
        beginningOfApril2 = beginningOfApril2Comps.date!
        
        middayApril2Comps = DateComponents(calendar: Calendar(identifier: .gregorian), timeZone: TimeZone(identifier: "Europe/Berlin"), year: 2020, month: 4, day: 2, hour: 12, minute: 0, second: 0)
        middayApril2 = middayApril2Comps.date!
    }
    
    func testFollowingMidnightUTC() throws {
        XCTAssertEqual(middayAprilFools.followingMidnightUTC, beginningOfApril2)
    }
    
    func testPreviousMidnightUTC() throws {
        XCTAssertEqual(middayApril2.precedingMidnightUTC, beginningOfApril2)
    }

}
