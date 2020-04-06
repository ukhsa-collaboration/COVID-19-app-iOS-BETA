//
//  RegistrationViewControllerTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class RegistrationViewControllerTests: TestCase {
    
    func testRegistration_failure() {
        let storyboard = UIStoryboard(name: "Registration", bundle: Bundle(for: RegistrationViewController.self))
        let vc = storyboard.instantiateViewController(withIdentifier: "RegistrationViewController") as! RegistrationViewController
        let registrationService = RegistrationServiceDouble()
        vc.registrationService = registrationService
        XCTAssertNotNil(vc.view)

        vc.didTapRegister(vc.registerButton)
        
        registrationService.completionHandler!(.failure(ErrorForTest()))
        XCTAssertTrue(vc.registerButton.isEnabled)
        XCTAssertFalse(vc.activityIndicator.isAnimating)
    }
    
    func testRegistration_timeout() {
        let storyboard = UIStoryboard(name: "Registration", bundle: Bundle(for: RegistrationViewController.self))
        let vc = storyboard.instantiateViewController(withIdentifier: "RegistrationViewController") as! RegistrationViewController
        let registrationService = RegistrationServiceDouble()
        vc.registrationService = registrationService
        let asyncAfterable = AsyncAfterableDouble()
        vc.mainQueue = asyncAfterable
        XCTAssertNotNil(vc.view)

        vc.didTapRegister(vc.registerButton)

        asyncAfterable.scheduledBlock?()

        XCTAssertTrue(vc.registerButton.isEnabled)
        XCTAssertFalse(vc.activityIndicator.isAnimating)
    }
}

class ErrorForTest: Error {
    
}
