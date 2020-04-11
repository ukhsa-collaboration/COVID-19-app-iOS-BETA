//
//  AppCoordinatorTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class AppCoordinatorTests: TestCase {

    func test_shows_you_are_okay_screen_when_diagnosis_is_nil() {
        let persistence = PersistenceDouble(diagnosis: nil)
        let container = ViewControllerContainerDouble()
        let coordinator = AppCoordinator(container: container, persistence: persistence, registrationService: RegistrationServiceDouble())

        coordinator.update()

        XCTAssertNotNil(container.currentChild as? StatusViewController)
    }

    func testShowView_diagnosisInfected() {
        let persistence = PersistenceDouble(diagnosis: .infected)
        let container = ViewControllerContainerDouble()
        let coordinator = AppCoordinator(container: container, persistence: persistence, registrationService: RegistrationServiceDouble())

        coordinator.update()

        XCTAssertNotNil(container.currentChild as? PleaseSelfIsolateViewController)
    }
    
    func testShowView_diagnosisNotInfected() {
        let persistence = PersistenceDouble(diagnosis: .notInfected)
        let container = ViewControllerContainerDouble()
        let coordinator = AppCoordinator(container: container, persistence: persistence, registrationService: RegistrationServiceDouble())

        coordinator.update()

        XCTAssertNotNil(container.currentChild as? StatusViewController)
    }
    
    func testShowView_diagnosisPotential() {
        let persistence = PersistenceDouble(diagnosis: .potential)
        let container = ViewControllerContainerDouble()
        let coordinator = AppCoordinator(container: container, persistence: persistence, registrationService: RegistrationServiceDouble())

        coordinator.update()
        
        XCTAssertNotNil(container.currentChild as? PotentialViewController)
    }
}
