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

        try! SecureRegistrationStorage.clear()
    }
    
    func testRegistration_success() {
        let storyboard = UIStoryboard.init(name: "Registration", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "RegistrationViewController") as! RegistrationViewController
        let delegate = RegistrationSavedDelegateDouble()
        let registrationService = RegistrationServiceDouble()

        vc.delegate = delegate
        vc.registrationService = registrationService

        XCTAssertNotNil(vc.view)

        vc.didTapRegister(vc.retryButton!)

        let registration = Registration(id: UUID(uuidString: "39B84598-3AD8-4900-B4E0-EE868773181D")!, secretKey: Data())
        registrationService.completionHandler!(.success((registration)))
        XCTAssertEqual(delegate.registration?.id, registration.id)
        XCTAssertEqual(delegate.registration?.secretKey, registration.secretKey)
    }
    
    func testRegistration_failure() {
        let storyboard = UIStoryboard.init(name: "Registration", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "RegistrationViewController") as! RegistrationViewController
        let registrationService = RegistrationServiceDouble()
        vc.registrationService = registrationService
        XCTAssertNotNil(vc.view)

        vc.didTapRegister(vc.retryButton!)
        
        registrationService.completionHandler!(.failure(ErrorForTest()))
        XCTAssertFalse(vc.retryButton.isHidden)
    }

}

class ErrorForTest: Error {
    
}

class RegistrationSavedDelegateDouble: RegistrationSavedDelegate {
    var registration: Registration?

    func registrationDidFinish(with registration: Registration) {
        self.registration = registration
    }
}
