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

        let button = PrimaryButton()
        vc.didTapRegister(button)
        
        registrationService.completionHandler!(.failure(ErrorForTest()))
        XCTAssertFalse(button.isHidden)
    }

}

class ErrorForTest: Error {
    
}
