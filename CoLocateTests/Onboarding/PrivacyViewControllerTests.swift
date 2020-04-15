//
//  PrivacyViewControllerTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class PrivacyViewControllerTests: TestCase {
    
    func testAlertsIfContinueTappedWithoutDataSharingAllowed() {
        let vc = PrivacyViewController.instantiate()
        let persistence = PersistenceDouble(allowedDataSharing: false)
        var continued = false
        vc.inject(persistence: persistence) {
            continued = true
        }
        parentViewControllerForTests.viewControllers = [vc]
        XCTAssertNotNil(vc.view)
        
        vc.continueTapped()
        
        XCTAssertFalse(continued)
        XCTAssertFalse(persistence.allowedDataSharing)
        XCTAssertNotNil(vc.presentedViewController as? UIAlertController)
    }
    
    func testContinuesIfContinueTappedWithDataSharingAllowed() {
        let vc = PrivacyViewController.instantiate()
        let persistence = PersistenceDouble(allowedDataSharing: false)
        var continued = false
        vc.inject(persistence: persistence) {
            continued = true
        }
        parentViewControllerForTests.viewControllers = [vc]
        XCTAssertNotNil(vc.view)

        vc.allowDataSharingSwitch.isOn = true
        vc.continueTapped()
        
        XCTAssertTrue(continued)
        XCTAssertTrue(persistence.allowedDataSharing)
        XCTAssertNil(vc.presentedViewController as? UIAlertController)
    }
}
