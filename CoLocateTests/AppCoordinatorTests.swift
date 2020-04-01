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
        let navController = UINavigationController()
        let coordinator = AppCoordinator(navController: navController, persistence: persistence, secureRequestFactory: SecureRequestFactoryDouble())

        let vc = coordinator.initialViewController()

        XCTAssertNotNil(vc as? OkNowViewController)
    }

    func testShowView_diagnosisUnknown() {
        let persistence = PersistenceDouble()
        persistence.diagnosis = .unknown
        let navController = UINavigationController()
        let coordinator = AppCoordinator(navController: navController, persistence: persistence, secureRequestFactory: SecureRequestFactoryDouble())
        
        coordinator.showAppropriateViewController()
        
        XCTAssertNotNil(navController.topViewController as? EnterDiagnosisTableViewController)
    }
    
    func testShowView_diagnosisInfected() {
        let persistence = PersistenceDouble()
        persistence.diagnosis = .infected
        let navController = UINavigationController()
        let coordinator = AppCoordinator(navController: navController, persistence: persistence, secureRequestFactory: SecureRequestFactoryDouble())

        coordinator.showAppropriateViewController()
        
        XCTAssertNotNil(navController.topViewController as? PleaseSelfIsolateViewController)
    }
    
    func testShowView_diagnosisNotInfected() {
        let persistence = PersistenceDouble()
        persistence.diagnosis = .notInfected
        let navController = UINavigationController()
        let coordinator = AppCoordinator(navController: navController, persistence: persistence, secureRequestFactory: SecureRequestFactoryDouble())

        coordinator.showAppropriateViewController()
        
        XCTAssertNotNil(navController.topViewController as? OkNowViewController)
    }

    
    func testShowView_diagnosisPotential() {
        let persistence = PersistenceDouble()
        persistence.diagnosis = .potential
        let navController = UINavigationController()
        let coordinator = AppCoordinator(navController: navController, persistence: persistence, secureRequestFactory: SecureRequestFactoryDouble())

        coordinator.showAppropriateViewController()
        
        XCTAssertNotNil(navController.topViewController as? PotentialViewController)
    }
    
    func testShowsPotentialWhenReceivingPotentialDiagnosis() {
        let persistence = PersistenceDouble()
        persistence.diagnosis = .unknown
        let navController = UINavigationController()
        let coordinator = AppCoordinator(navController: navController, persistence: persistence, secureRequestFactory: SecureRequestFactoryDouble())

        coordinator.persistence(persistence, didRecordDiagnosis: .potential)

        XCTAssertNotNil(navController.topViewController as? PotentialViewController)
    }
    
    func testShowsOkWhenReceivingNotInfectedDiagnosis() {
        let persistence = PersistenceDouble()
        persistence.diagnosis = .unknown
        let navController = UINavigationController()
        let coordinator = AppCoordinator(navController: navController, persistence: persistence, secureRequestFactory: SecureRequestFactoryDouble())

        coordinator.persistence(persistence, didRecordDiagnosis: .notInfected)

        XCTAssertNotNil(navController.topViewController as? OkNowViewController)
    }

    func testShowsPleaseIsolateWhenReceivingInfectedDiagnosis() {
        let persistence = PersistenceDouble()
        persistence.diagnosis = .unknown
        let navController = UINavigationController()
        let coordinator = AppCoordinator(navController: navController, persistence: persistence, secureRequestFactory: SecureRequestFactoryDouble())

        coordinator.persistence(persistence, didRecordDiagnosis: .infected)

        let viewController = navController.topViewController as? PleaseSelfIsolateViewController
        XCTAssertNotNil(viewController)
        XCTAssertNotNil(viewController?.requestFactory)
    }
}
