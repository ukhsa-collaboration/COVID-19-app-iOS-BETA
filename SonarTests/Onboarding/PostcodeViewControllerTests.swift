//
//  PostcodeViewControllerTests.swift
//  SonarTests
//
//  Created by NHSX on 4/10/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class PostcodeViewControllerTests: TestCase {

    func testRejectsInvalidPostcodes() {
        let persistence = PersistenceDouble()
        let vc = PostcodeViewController.instantiate()
        var continued = false
        vc.inject(persistence: persistence, notificationCenter: NotificationCenter()) { continued = true }
        parentViewControllerForTests.viewControllers = [vc]

        XCTAssertNotNil(vc.view)
        XCTAssertTrue(vc.errorView.isHidden)

        vc.postcodeField.text = "1"
        vc.didTapContinue()
        
        XCTAssertNil(persistence.partialPostcode)
        XCTAssertFalse(continued)

        XCTAssertFalse(vc.errorView.isHidden)
    }
    
    func testAcceptsValidPostcodes() {
        let persistence = PersistenceDouble()
        let vc = PostcodeViewController.instantiate()
        var continued = false
        vc.inject(persistence: persistence, notificationCenter: NotificationCenter()) { continued = true }
        parentViewControllerForTests.viewControllers = [vc]
        XCTAssertNotNil(vc.view)
        
        vc.postcodeField.text = "X1"
        vc.didTapContinue()
        
        XCTAssertEqual(persistence.partialPostcode, "X1")
        XCTAssertTrue(continued)
        XCTAssertTrue(vc.errorView.isHidden)
    }
    
    func testRemovesTrailingNewline() {
        let persistence = PersistenceDouble()
        let vc = PostcodeViewController.instantiate()
        var continued = false
        vc.inject(persistence: persistence, notificationCenter: NotificationCenter()) { continued = true }
        parentViewControllerForTests.viewControllers = [vc]
        XCTAssertNotNil(vc.view)
        
        vc.postcodeField.text = "ABR7\n"
        vc.didTapContinue()
        
        XCTAssertEqual(persistence.partialPostcode, "ABR7")
        XCTAssertTrue(continued)
        XCTAssertNil(vc.presentedViewController)
    }
    
    func testConvertsToUppercase() {
        let persistence = PersistenceDouble()
        let vc = PostcodeViewController.instantiate()
        var continued = false
        vc.inject(persistence: persistence, notificationCenter: NotificationCenter()) { continued = true }
        parentViewControllerForTests.viewControllers = [vc]
        XCTAssertNotNil(vc.view)
        
        vc.postcodeField.text = "abr7\n"
        vc.didTapContinue()
        
        XCTAssertEqual(persistence.partialPostcode, "ABR7")
        XCTAssertTrue(continued)
        XCTAssertNil(vc.presentedViewController)
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
