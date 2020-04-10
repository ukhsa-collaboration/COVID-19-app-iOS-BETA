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
        vc.inject(persistence: persistence)
        let unwinder = Unwinder()
        parentViewControllerForTests.show(viewController: unwinder)
        unwinder.present(vc, animated: false)
        
        vc.postcodeField.text = "1234"
        vc.didTapContinue()
        
        XCTAssertEqual(persistence.partialPostcode, "1234")
        XCTAssertTrue(unwinder.didUnwind)
    }
    
    func testDoesNotContinueWithoutInput() {
        let persistence = PersistenceDouble(partialPostcode: nil)
        let vc = PostcodeViewController.instantiate()
        vc.inject(persistence: persistence)
        let unwinder = Unwinder()
        parentViewControllerForTests.show(viewController: unwinder)
        unwinder.present(vc, animated: false)
        
        vc.didTapContinue()
        
        XCTAssertNil(persistence.partialPostcode)
        XCTAssertFalse(unwinder.didUnwind)
    }
    
    func testDoesNotAcceptMoreThanFourChars_insertingOne() {
        let vc = PostcodeViewController.instantiate()
        XCTAssertNotNil(vc.view)
        
        vc.postcodeField.text = "123"
        XCTAssertTrue(vc.textField(vc.postcodeField, shouldChangeCharactersIn: NSRange(location: 3, length: 0), replacementString: "4"))
        
        vc.postcodeField.text = "1234"
        XCTAssertFalse(vc.textField(vc.postcodeField, shouldChangeCharactersIn: NSRange(location: 3, length: 0), replacementString: "5"))
    }
    
    func testDoesNotAcceptMoreThanFourChars_insertingMany() {
        let vc = PostcodeViewController.instantiate()
        XCTAssertNotNil(vc.view)
        
        vc.postcodeField.text = "1"
        XCTAssertTrue(vc.textField(vc.postcodeField, shouldChangeCharactersIn: NSRange(location: 1, length: 0), replacementString: "234"))
        
        XCTAssertFalse(vc.textField(vc.postcodeField, shouldChangeCharactersIn: NSRange(location: 1, length: 0), replacementString: "2345"))
    }
        
    func testDoesNotAcceptMoreThanFourChars_replacing() {
        let vc = PostcodeViewController.instantiate()
        XCTAssertNotNil(vc.view)
        
        vc.postcodeField.text = "123"
        XCTAssertTrue(vc.textField(vc.postcodeField, shouldChangeCharactersIn: NSRange(location: 2, length: 1), replacementString: "34"))
        
        XCTAssertFalse(vc.textField(vc.postcodeField, shouldChangeCharactersIn: NSRange(location: 2, length: 1), replacementString: "345"))
    }
    
    func testAcceptsDeletion() {
        let vc = PostcodeViewController.instantiate()
        XCTAssertNotNil(vc.view)
        
        vc.postcodeField.text = "1234"
        XCTAssertTrue(vc.textField(vc.postcodeField, shouldChangeCharactersIn: NSRange(location: 3, length: 1), replacementString: ""))
    }
    
    func testEnablesButtonWhenFourCharsEntered() {
        let vc = PostcodeViewController.instantiate()
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

fileprivate class Unwinder: UIViewController {
    var didUnwind = false
    @IBAction func unwindFromPostcode(unwindSegue: UIStoryboardSegue) {
        didUnwind = true
    }
}
