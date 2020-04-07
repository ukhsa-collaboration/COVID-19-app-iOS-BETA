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

    func test_shows_you_are_okay_screen_when_diagnosis_is_unknown() {
        let persistence = PersistenceDouble()
        persistence.diagnosis = .unknown
        let coordinator = AppCoordinator(rootViewController: RootViewController(), persistence: persistence, secureRequestFactory: SecureRequestFactoryDouble())

        let vc = coordinator.initialViewController()

        XCTAssertNotNil(vc as? OkViewController)
    }

    func testShowView_diagnosisUnknown() {
        let persistence = PersistenceDouble()
        persistence.diagnosis = .unknown
        let rootViewController = RootViewController()
        let coordinator = AppCoordinator(rootViewController: rootViewController, persistence: persistence, secureRequestFactory: SecureRequestFactoryDouble())
        
        coordinator.showAppropriateViewController()
        
        XCTAssertNotNil(rootViewController.children.first as? EnterDiagnosisTableViewController)
    }
    
    func testShowView_diagnosisInfected() {
        let persistence = PersistenceDouble()
        persistence.diagnosis = .infected
        let rootViewController = RootViewController()
        let coordinator = AppCoordinator(rootViewController: rootViewController, persistence: persistence, secureRequestFactory: SecureRequestFactoryDouble())

        coordinator.showAppropriateViewController()
        
        XCTAssertNotNil(rootViewController.children.first as? PleaseSelfIsolateViewController)
    }
    
    func testShowView_diagnosisNotInfected() {
        let persistence = PersistenceDouble()
        persistence.diagnosis = .notInfected
        let rootViewController = RootViewController()
        let coordinator = AppCoordinator(rootViewController: rootViewController, persistence: persistence, secureRequestFactory: SecureRequestFactoryDouble())

        coordinator.showAppropriateViewController()
        
        XCTAssertNotNil(rootViewController.children.first as? OkViewController)
    }

    
    func testShowView_diagnosisPotential() {
        let persistence = PersistenceDouble()
        persistence.diagnosis = .potential
        let rootViewController = RootViewController()
        let coordinator = AppCoordinator(rootViewController: rootViewController, persistence: persistence, secureRequestFactory: SecureRequestFactoryDouble())

        coordinator.showAppropriateViewController()
        
        XCTAssertNotNil(rootViewController.children.first as? PotentialViewController)
    }
}
