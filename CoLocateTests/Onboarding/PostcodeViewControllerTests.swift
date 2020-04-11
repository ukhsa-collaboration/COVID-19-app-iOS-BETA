//
//  PostcodeViewControllerTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class PostcodeViewControllerTests: TestCase {
    func testContinuesWithValidInput() {
        let persistence = PersistenceDouble()
        let vc = PostcodeViewController.instantiate()
        var continued = false
        vc.inject(persistence: persistence, notificationCenter: NotificationCenter()) { continued = true }
        XCTAssertNotNil(vc.view)
        
        vc.postcodeField.text = "1234"
        vc.didTapContinue()
        
        XCTAssertEqual(persistence.partialPostcode, "1234")
        XCTAssertTrue(continued)
    }
    
    func testDoesNotContinueWithoutInput() {
        let persistence = PersistenceDouble(partialPostcode: nil)
        let vc = PostcodeViewController.instantiate()
        var continued = false
        vc.inject(persistence: persistence, notificationCenter: NotificationCenter()) { continued = true }
        XCTAssertNotNil(vc.view)

        vc.didTapContinue()
        
        XCTAssertNil(persistence.partialPostcode)
        XCTAssertFalse(continued)
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
    
    func testEnablesButtonWhenFourCharsEntered() {
        let vc = PostcodeViewController.instantiate()
        vc.inject(persistence: PersistenceDouble(), notificationCenter: NotificationCenter()) {}
        XCTAssertNotNil(vc.view)
        
        XCTAssertFalse(vc.continueButton?.isEnabled ?? true)
        vc.postcodeField.text = "123"
        vc.postcodeField.sendActions(for: .editingChanged)
        XCTAssertFalse(vc.continueButton?.isEnabled ?? true)
        vc.postcodeField.text = "1234"
        vc.postcodeField.sendActions(for: .editingChanged)
        XCTAssertTrue(vc.continueButton?.isEnabled ?? false)
    }
}
