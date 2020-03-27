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
        let coordinator = AppCoordinator(diagnosisService: DiagnosisService(), notificationManager: NotificationManagerDouble(), registrationService: RegistrationServiceDouble())
        
        coordinator.showViewAfterPermissions()
        
        XCTAssertNotNil(coordinator.navigationController.topViewController as? RegistrationViewController)
    }
    
    func testShowViewAfterPermissions_registered_diagnosisUnknown() {
        register()
        let diagnosisService = DiagnosisServiceDouble()
        diagnosisService.currentDiagnosis = .unknown
        let coordinator = AppCoordinator(diagnosisService: diagnosisService, notificationManager: NotificationManagerDouble(), registrationService: RegistrationServiceDouble())
        
        coordinator.showViewAfterPermissions()
        
        XCTAssertNotNil(coordinator.navigationController.topViewController as? EnterDiagnosisTableViewController)
    }
    
    func testShowViewAfterPermissions_registered_diagnosisInfected() {
        register()
        let diagnosisService = DiagnosisServiceDouble()
        diagnosisService.currentDiagnosis = .infected
        let coordinator = AppCoordinator(diagnosisService: diagnosisService, notificationManager: NotificationManagerDouble(), registrationService: RegistrationServiceDouble())

        coordinator.showViewAfterPermissions()
        
        XCTAssertNotNil(coordinator.navigationController.topViewController as? PleaseSelfIsolateViewController)
    }
    
    func testShowViewAfterPermissions_registered_diagnosisNotInfected() {
        register()
        let diagnosisService = DiagnosisServiceDouble()
        diagnosisService.currentDiagnosis = .notInfected
        let coordinator = AppCoordinator(diagnosisService: diagnosisService, notificationManager: NotificationManagerDouble(), registrationService: RegistrationServiceDouble())

        coordinator.showViewAfterPermissions()
        
        XCTAssertNotNil(coordinator.navigationController.topViewController as? OkNowViewController)
    }

    
    func testShowViewAfterPermissions_registered_diagnosisPotential() {
        register()
        let diagnosisService = DiagnosisServiceDouble()
        diagnosisService.currentDiagnosis = .potential
        let coordinator = AppCoordinator(diagnosisService: diagnosisService, notificationManager: NotificationManagerDouble(), registrationService: RegistrationServiceDouble())

        coordinator.showViewAfterPermissions()
        
        XCTAssertNotNil(coordinator.navigationController.topViewController as? PotentialViewController)
    }

    private func register() {
        try! SecureRegistrationStorage.shared.set(registration: Registration(id: UUID(), secretKey: Data()))
    }
}
