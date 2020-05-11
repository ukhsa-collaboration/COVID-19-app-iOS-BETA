//
//  StatusStateMachineTests.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class StatusStateMachineMigrationTests: XCTestCase {

    func testDefaultsToOk() {
        let state = StatusStateMachine.migrate(
            diagnosis: nil,
            potentiallyExposedOn: nil
        )

        XCTAssertEqual(state, .ok)
    }

}
