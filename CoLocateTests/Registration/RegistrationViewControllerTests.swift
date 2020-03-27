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
        XCTAssertFalse(appCoordinator.enterDiagnosisWasCalled)
        
        registrationService.completionHandler!(.success(()))
        XCTAssertTrue(appCoordinator.enterDiagnosisWasCalled)
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
        XCTAssertFalse(appCoordinator.enterDiagnosisWasCalled)
        XCTAssertFalse(vc.retryButton.isHidden)
    }

}

class ErrorForTest: Error {
    
}

class AppCoordinatorDouble: AppCoordinator {
    var enterDiagnosisWasCalled = false

    init() {
        super.init(diagnosisService: DiagnosisService(),
                   notificationManager: NotificationManagerDouble(),
                   registrationService: RegistrationServiceDouble())
    }

    override func launchEnterDiagnosis() {
        enterDiagnosisWasCalled = true
    }
    
    var okNowWasCalled = false
    
    override func launchOkNowVC() {
        okNowWasCalled = true
    }
}
