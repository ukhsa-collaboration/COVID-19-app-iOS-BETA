//
//  UnclearTestStatusTests.swift
//  SonarUITests
//
//  Created by NHSX on 21/05/2020
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest

class UnclearTestStatusTests: ScreenTestCase {

    override var screen: Screen { .unclearTestStatus }

    func testPositiveTestResultFlow() {

        // Ensure the positive test status page has the correct heading
        let unclearTestStatusPage = UnclearTestStatusPage(app)
        XCTAssertTrue(unclearTestStatusPage.heading.exists)
                
        // Ensure the positive test status shows the checkin popup after 7 days
        XCTAssertTrue(unclearTestStatusPage.drawerTitle.exists)
    }
}
