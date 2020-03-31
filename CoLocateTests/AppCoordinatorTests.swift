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
        let persistance = PersistanceDouble()
        persistance.diagnosis = .unknown
        let navController = UINavigationController()
        let coordinator = AppCoordinator(navController: navController, persistance: persistance, secureRequestFactory: SecureRequestFactoryDouble())

        let vc = coordinator.initialViewController()

        XCTAssertNotNil(vc as? OkNowViewController)
    }

    func testShowView_diagnosisUnknown() {
        let persistance = PersistanceDouble()
        persistance.diagnosis = .unknown
        let navController = UINavigationController()
        let coordinator = AppCoordinator(navController: navController, persistance: persistance, secureRequestFactory: SecureRequestFactoryDouble())
        
        coordinator.showAppropriateViewController()
        
        XCTAssertNotNil(navController.topViewController as? EnterDiagnosisTableViewController)
    }
    
    func testShowView_diagnosisInfected() {
        let persistance = PersistanceDouble()
        persistance.diagnosis = .infected
        let navController = UINavigationController()
        let coordinator = AppCoordinator(navController: navController, persistance: persistance, secureRequestFactory: SecureRequestFactoryDouble())

        coordinator.showAppropriateViewController()
        
        XCTAssertNotNil(navController.topViewController as? PleaseSelfIsolateViewController)
    }
    
    func testShowView_diagnosisNotInfected() {
        let persistance = PersistanceDouble()
        persistance.diagnosis = .notInfected
        let navController = UINavigationController()
        let coordinator = AppCoordinator(navController: navController, persistance: persistance, secureRequestFactory: SecureRequestFactoryDouble())

        coordinator.showAppropriateViewController()
        
        XCTAssertNotNil(navController.topViewController as? OkNowViewController)
    }

    
    func testShowView_diagnosisPotential() {
        let persistance = PersistanceDouble()
        persistance.diagnosis = .potential
        let navController = UINavigationController()
        let coordinator = AppCoordinator(navController: navController, persistance: persistance, secureRequestFactory: SecureRequestFactoryDouble())

        coordinator.showAppropriateViewController()
        
        XCTAssertNotNil(navController.topViewController as? PotentialViewController)
    }
    
    func testShowsPotentialWhenReceivingPotentialDiagnosis() {
        let persistance = PersistanceDouble()
        persistance.diagnosis = .unknown
        let navController = UINavigationController()
        let coordinator = AppCoordinator(navController: navController, persistance: persistance, secureRequestFactory: SecureRequestFactoryDouble())

        coordinator.persistance(persistance, didRecordDiagnosis: .potential)

        XCTAssertNotNil(navController.topViewController as? PotentialViewController)
    }
    
    func testShowsOkWhenReceivingNotInfectedDiagnosis() {
        let persistance = PersistanceDouble()
        persistance.diagnosis = .unknown
        let navController = UINavigationController()
        let coordinator = AppCoordinator(navController: navController, persistance: persistance, secureRequestFactory: SecureRequestFactoryDouble())

        coordinator.persistance(persistance, didRecordDiagnosis: .notInfected)

        XCTAssertNotNil(navController.topViewController as? OkNowViewController)
    }

    func testShowsPleaseIsolateWhenReceivingInfectedDiagnosis() {
        let persistance = PersistanceDouble()
        persistance.diagnosis = .unknown
        let navController = UINavigationController()
        let coordinator = AppCoordinator(navController: navController, persistance: persistance, secureRequestFactory: SecureRequestFactoryDouble())

        coordinator.persistance(persistance, didRecordDiagnosis: .infected)

        let viewController = navController.topViewController as? PleaseSelfIsolateViewController
        XCTAssertNotNil(viewController)
        XCTAssertNotNil(viewController?.requestFactory)
    }
}
