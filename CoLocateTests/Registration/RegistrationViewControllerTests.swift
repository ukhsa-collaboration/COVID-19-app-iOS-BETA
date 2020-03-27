//
//  RegistrationViewControllerTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class RegistrationViewControllerTests: XCTestCase {

    override class func setUp() {
        super.setUp()

        try! SecureRegistrationStorage.shared.clear()
    }
    
    func testRegistration_success() {
        let storyboard = UIStoryboard.init(name: "Registration", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "RegistrationViewController") as! RegistrationViewController
        let appCoordinator = AppCoordinatorDouble()
        vc.coordinator = appCoordinator
        let registrationService = RegistrationServiceDouble()
        vc.registrationService = registrationService
        XCTAssertNotNil(vc.view)

        vc.didTapRegister(vc.retryButton!)
        XCTAssertFalse(appCoordinator.showViewAfterPermissionsWasCalled)
        
        registrationService.completionHandler!(.success(()))
        XCTAssertTrue(appCoordinator.showViewAfterPermissionsWasCalled)
    }
    
    func testRegistration_failure() {
        let storyboard = UIStoryboard.init(name: "Registration", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "RegistrationViewController") as! RegistrationViewController
        let appCoordinator = AppCoordinatorDouble()
        vc.coordinator = appCoordinator
        let registrationService = RegistrationServiceDouble()
        vc.registrationService = registrationService
        XCTAssertNotNil(vc.view)

        vc.didTapRegister(vc.retryButton!)
        
        registrationService.completionHandler!(.failure(ErrorForTest()))
        XCTAssertFalse(appCoordinator.showViewAfterPermissionsWasCalled)
        XCTAssertFalse(vc.retryButton.isHidden)
    }

}

class ErrorForTest: Error {
    
}

class AppCoordinatorDouble: AppCoordinator {
    var showViewAfterPermissionsWasCalled = false

    init() {
        super.init(navController: UINavigationController(),
                   diagnosisService: DiagnosisService(),
                   notificationManager: NotificationManagerDouble(),
                   registrationService: RegistrationServiceDouble())
    }

    override func showViewAfterPermissions() {
        showViewAfterPermissionsWasCalled = true
    }
}
