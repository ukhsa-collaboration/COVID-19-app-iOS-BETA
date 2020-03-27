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

        try! SecureRegistrationStorage.shared.clear()
    }
    
    func testShowViewAfterPermissions_notRegistered() {
        let navController = UINavigationController()
        let coordinator = AppCoordinator(navController: navController, diagnosisService: DiagnosisService(), notificationManager: NotificationManagerDouble(), registrationService: RegistrationServiceDouble())
        
        coordinator.showViewAfterPermissions()
        
        XCTAssertNotNil(navController.topViewController as? RegistrationViewController)
    }
    
    func testShowViewAfterPermissions_registered_diagnosisUnknown() {
        register()
        let diagnosisService = DiagnosisServiceDouble()
        diagnosisService.currentDiagnosis = .unknown
        let navController = UINavigationController()
        let coordinator = AppCoordinator(navController: navController, diagnosisService: diagnosisService, notificationManager: NotificationManagerDouble(), registrationService: RegistrationServiceDouble())
        
        coordinator.showViewAfterPermissions()
        
        XCTAssertNotNil(navController.topViewController as? EnterDiagnosisTableViewController)
    }
    
    func testShowViewAfterPermissions_registered_diagnosisInfected() {
        register()
        let diagnosisService = DiagnosisServiceDouble()
        diagnosisService.currentDiagnosis = .infected
        let navController = UINavigationController()
        let coordinator = AppCoordinator(navController: navController, diagnosisService: diagnosisService, notificationManager: NotificationManagerDouble(), registrationService: RegistrationServiceDouble())

        coordinator.showViewAfterPermissions()
        
        XCTAssertNotNil(navController.topViewController as? PleaseSelfIsolateViewController)
    }
    
    func testShowViewAfterPermissions_registered_diagnosisNotInfected() {
        register()
        let diagnosisService = DiagnosisServiceDouble()
        diagnosisService.currentDiagnosis = .notInfected
        let navController = UINavigationController()
        let coordinator = AppCoordinator(navController: navController, diagnosisService: diagnosisService, notificationManager: NotificationManagerDouble(), registrationService: RegistrationServiceDouble())

        coordinator.showViewAfterPermissions()
        
        XCTAssertNotNil(navController.topViewController as? OkNowViewController)
    }

    
    func testShowViewAfterPermissions_registered_diagnosisPotential() {
        register()
        let diagnosisService = DiagnosisServiceDouble()
        diagnosisService.currentDiagnosis = .potential
        let navController = UINavigationController()
        let coordinator = AppCoordinator(navController: navController, diagnosisService: diagnosisService, notificationManager: NotificationManagerDouble(), registrationService: RegistrationServiceDouble())

        coordinator.showViewAfterPermissions()
        
        XCTAssertNotNil(navController.topViewController as? PotentialViewController)
    }
    
    func testShowsPotentialWhenReceivingPotentialDiagnosis() {
        register()
        let diagnosisService = DiagnosisServiceDouble()
        diagnosisService.currentDiagnosis = .unknown
        let navController = UINavigationController()
        let coordinator = AppCoordinator(navController: navController, diagnosisService: diagnosisService, notificationManager: NotificationManagerDouble(), registrationService: RegistrationServiceDouble())

        coordinator.diagnosisService(diagnosisService, didRecordDiagnosis: .potential)

        XCTAssertNotNil(navController.topViewController as? PotentialViewController)
    }
    
    func testShowsOkWhenReceivingNotInfectedDiagnosis() {
        register()
        let diagnosisService = DiagnosisServiceDouble()
        diagnosisService.currentDiagnosis = .unknown
        let navController = UINavigationController()
        let coordinator = AppCoordinator(navController: navController, diagnosisService: diagnosisService, notificationManager: NotificationManagerDouble(), registrationService: RegistrationServiceDouble())

        coordinator.diagnosisService(diagnosisService, didRecordDiagnosis: .notInfected)

        XCTAssertNotNil(navController.topViewController as? OkNowViewController)
    }

    func testShowsPleaseIsolateWhenReceivingInfectedDiagnosis() {
        register()
        let diagnosisService = DiagnosisServiceDouble()
        diagnosisService.currentDiagnosis = .unknown
        let navController = UINavigationController()
        let coordinator = AppCoordinator(navController: navController, diagnosisService: diagnosisService, notificationManager: NotificationManagerDouble(), registrationService: RegistrationServiceDouble())

        coordinator.diagnosisService(diagnosisService, didRecordDiagnosis: .infected)

        XCTAssertNotNil(navController.topViewController as? PleaseSelfIsolateViewController)
    }

    private func register() {
        try! SecureRegistrationStorage.shared.set(registration: Registration(id: UUID(), secretKey: Data()))
    }
}
