//
//  PostcodeViewControllerTests.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class PostcodeViewControllerTests: TestCase {
    func testAcceptsTwoCharacters() {
        let persistence = PersistenceDouble()
        let vc = PostcodeViewController.instantiate()
        var continued = false
        vc.inject(persistence: persistence, notificationCenter: NotificationCenter()) { continued = true }
        parentViewControllerForTests.viewControllers = [vc]
        XCTAssertNotNil(vc.view)
        
        vc.postcodeField.text = "1X"
        vc.didTapContinue()
        
        XCTAssertEqual(persistence.partialPostcode, "1X")
        XCTAssertTrue(continued)
        XCTAssertNil(vc.presentedViewController)
    }
    
    func testAcceptsFourCharacters() {
        let persistence = PersistenceDouble()
        let vc = PostcodeViewController.instantiate()
        var continued = false
        vc.inject(persistence: persistence, notificationCenter: NotificationCenter()) { continued = true }
        parentViewControllerForTests.viewControllers = [vc]
        XCTAssertNotNil(vc.view)
        
        vc.postcodeField.text = "1XYZ"
        vc.didTapContinue()
        
        XCTAssertEqual(persistence.partialPostcode, "1XYZ")
        XCTAssertTrue(continued)
        XCTAssertNil(vc.presentedViewController)
    }
    
    func testIgnoresTrailingNewline() {
        let persistence = PersistenceDouble()
        let vc = PostcodeViewController.instantiate()
        var continued = false
        vc.inject(persistence: persistence, notificationCenter: NotificationCenter()) { continued = true }
        parentViewControllerForTests.viewControllers = [vc]
        XCTAssertNotNil(vc.view)
        
        vc.postcodeField.text = "1XYZ\n"
        vc.didTapContinue()
        
        XCTAssertEqual(persistence.partialPostcode, "1XYZ")
        XCTAssertTrue(continued)
        XCTAssertNil(vc.presentedViewController)
    }
    

    
    func testValidationIsCaseInsensitive() {
        let persistence = PersistenceDouble()
        let vc = PostcodeViewController.instantiate()
        var continued = false
        vc.inject(persistence: persistence, notificationCenter: NotificationCenter()) { continued = true }
        parentViewControllerForTests.viewControllers = [vc]
        XCTAssertNotNil(vc.view)
        
        vc.postcodeField.text = "aB"
        vc.didTapContinue()
        
        XCTAssertEqual(persistence.partialPostcode, "aB")
        XCTAssertTrue(continued)
        XCTAssertNil(vc.presentedViewController)
    }
    
    func testDoesNotContinueWithoutInput() {
        let persistence = PersistenceDouble(partialPostcode: nil)
        let vc = PostcodeViewController.instantiate()
        var continued = false
        vc.inject(persistence: persistence, notificationCenter: NotificationCenter()) { continued = true }
        parentViewControllerForTests.viewControllers = [vc]
        XCTAssertNotNil(vc.view)

        vc.didTapContinue()
        
        XCTAssertNil(persistence.partialPostcode)
        XCTAssertFalse(continued)
        XCTAssertNotNil(vc.presentedViewController as? UIAlertController)
    }
    
    func testDoesNotContinueWithLessThanTwoChars() {
        let persistence = PersistenceDouble()
        let vc = PostcodeViewController.instantiate()
        var continued = false
        vc.inject(persistence: persistence, notificationCenter: NotificationCenter()) { continued = true }
        parentViewControllerForTests.viewControllers = [vc]
        XCTAssertNotNil(vc.view)
        
        vc.postcodeField.text = "1"
        vc.didTapContinue()
        
        XCTAssertNil(persistence.partialPostcode)
        XCTAssertFalse(continued)
        XCTAssertNotNil(vc.presentedViewController as? UIAlertController)
    }
    
    func testDoesNotContinueWithNonAlphanumerics() {
        let persistence = PersistenceDouble()
        let vc = PostcodeViewController.instantiate()
        var continued = false
        vc.inject(persistence: persistence, notificationCenter: NotificationCenter()) { continued = true }
        parentViewControllerForTests.viewControllers = [vc]
        XCTAssertNotNil(vc.view)
        
        vc.postcodeField.text = "1~"
        vc.didTapContinue()
        
        XCTAssertNil(persistence.partialPostcode)
        XCTAssertFalse(continued)
        XCTAssertNotNil(vc.presentedViewController as? UIAlertController)
    }
    
    func testDoesNotAcceptMoreThanFourChars_insertingOne() {
        let vc = PostcodeViewController.instantiate()
        vc.inject(persistence: PersistenceDouble(), notificationCenter: NotificationCenter()) {}
        XCTAssertNotNil(vc.view)
        
        vc.postcodeField.text = "123"
        XCTAssertTrue(vc.textField(vc.postcodeField, shouldChangeCharactersIn: NSRange(location: 3, length: 0), replacementString: "4"))
        
        vc.postcodeField.text = "1234"
        XCTAssertFalse(vc.textField(vc.postcodeField, shouldChangeCharactersIn: NSRange(location: 3, length: 0), replacementString: "5"))
    }
    
    func testDoesNotAcceptMoreThanFourChars_insertingMany() {
        let vc = PostcodeViewController.instantiate()
        vc.inject(persistence: PersistenceDouble(), notificationCenter: NotificationCenter()) {}
        XCTAssertNotNil(vc.view)
        
        vc.postcodeField.text = "1"
        XCTAssertTrue(vc.textField(vc.postcodeField, shouldChangeCharactersIn: NSRange(location: 1, length: 0), replacementString: "234"))
        
        XCTAssertFalse(vc.textField(vc.postcodeField, shouldChangeCharactersIn: NSRange(location: 1, length: 0), replacementString: "2345"))
    }
        
    func testDoesNotAcceptMoreThanFourChars_replacing() {
        let vc = PostcodeViewController.instantiate()
        vc.inject(persistence: PersistenceDouble(), notificationCenter: NotificationCenter()) {}
        XCTAssertNotNil(vc.view)
        
        vc.postcodeField.text = "123"
        XCTAssertTrue(vc.textField(vc.postcodeField, shouldChangeCharactersIn: NSRange(location: 2, length: 1), replacementString: "34"))
        
        XCTAssertFalse(vc.textField(vc.postcodeField, shouldChangeCharactersIn: NSRange(location: 2, length: 1), replacementString: "345"))
    }
    
    func testAcceptsDeletion() {
        let vc = PostcodeViewController.instantiate()
        vc.inject(persistence: PersistenceDouble(), notificationCenter: NotificationCenter()) {}
        XCTAssertNotNil(vc.view)
        
        vc.postcodeField.text = "1234"
        XCTAssertTrue(vc.textField(vc.postcodeField, shouldChangeCharactersIn: NSRange(location: 3, length: 1), replacementString: ""))
    }
}
