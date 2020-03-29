//
//  AppCoordinatorTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class AppCoordinatorTests: XCTestCase {
    override func setUp() {
        super.setUp()

        try! SecureRegistrationStorage.clear()
    }

    func testShowView_diagnosisUnknown() {
        let diagnosisService = DiagnosisServiceDouble()
        diagnosisService.currentDiagnosis = .unknown
        let navController = UINavigationController()
        let coordinator = AppCoordinator(navController: navController, diagnosisService: diagnosisService, secureRequestFactory: SecureRequestFactoryDouble())
        
        coordinator.showAppropriateViewController()
        
        XCTAssertNotNil(navController.topViewController as? EnterDiagnosisTableViewController)
    }
    
    func testShowView_diagnosisInfected() {
        let diagnosisService = DiagnosisServiceDouble()
        diagnosisService.currentDiagnosis = .infected
        let navController = UINavigationController()
        let coordinator = AppCoordinator(navController: navController, diagnosisService: diagnosisService, secureRequestFactory: SecureRequestFactoryDouble())

        coordinator.showAppropriateViewController()
        
        XCTAssertNotNil(navController.topViewController as? PleaseSelfIsolateViewController)
    }
    
    func testShowView_diagnosisNotInfected() {
        let diagnosisService = DiagnosisServiceDouble()
        diagnosisService.currentDiagnosis = .notInfected
        let navController = UINavigationController()
        let coordinator = AppCoordinator(navController: navController, diagnosisService: diagnosisService, secureRequestFactory: SecureRequestFactoryDouble())

        coordinator.showAppropriateViewController()
        
        XCTAssertNotNil(navController.topViewController as? OkNowViewController)
    }

    
    func testShowView_diagnosisPotential() {
        let diagnosisService = DiagnosisServiceDouble()
        diagnosisService.currentDiagnosis = .potential
        let navController = UINavigationController()
        let coordinator = AppCoordinator(navController: navController, diagnosisService: diagnosisService, secureRequestFactory: SecureRequestFactoryDouble())

        coordinator.showAppropriateViewController()
        
        XCTAssertNotNil(navController.topViewController as? PotentialViewController)
    }
    
    func testShowsPotentialWhenReceivingPotentialDiagnosis() {
        let diagnosisService = DiagnosisServiceDouble()
        diagnosisService.currentDiagnosis = .unknown
        let navController = UINavigationController()
        let coordinator = AppCoordinator(navController: navController, diagnosisService: diagnosisService, secureRequestFactory: SecureRequestFactoryDouble())

        coordinator.diagnosisService(diagnosisService, didRecordDiagnosis: .potential)

        XCTAssertNotNil(navController.topViewController as? PotentialViewController)
    }
    
    func testShowsOkWhenReceivingNotInfectedDiagnosis() {
        let diagnosisService = DiagnosisServiceDouble()
        diagnosisService.currentDiagnosis = .unknown
        let navController = UINavigationController()
        let coordinator = AppCoordinator(navController: navController, diagnosisService: diagnosisService, secureRequestFactory: SecureRequestFactoryDouble())

        coordinator.diagnosisService(diagnosisService, didRecordDiagnosis: .notInfected)

        XCTAssertNotNil(navController.topViewController as? OkNowViewController)
    }

    func testShowsPleaseIsolateWhenReceivingInfectedDiagnosis() {
        let diagnosisService = DiagnosisServiceDouble()
        diagnosisService.currentDiagnosis = .unknown
        let navController = UINavigationController()
        let coordinator = AppCoordinator(navController: navController, diagnosisService: diagnosisService, secureRequestFactory: SecureRequestFactoryDouble())

        coordinator.diagnosisService(diagnosisService, didRecordDiagnosis: .infected)

        let viewController = navController.topViewController as? PleaseSelfIsolateViewController
        XCTAssertNotNil(viewController)
        XCTAssertNotNil(viewController?.requestFactory)
    }
}
