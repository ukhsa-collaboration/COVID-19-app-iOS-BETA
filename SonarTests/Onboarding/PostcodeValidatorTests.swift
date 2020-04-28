//
//  PostcodeValidatorTests.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class PostcodeValidatorTests: XCTestCase {
    
    func testIsValid() {
        XCTAssertTrue(PostcodeValidator.isValid("A1"))
        XCTAssertTrue(PostcodeValidator.isValid("A19"))
        XCTAssertTrue(PostcodeValidator.isValid("A1A"))
        XCTAssertTrue(PostcodeValidator.isValid("AR"))
        XCTAssertTrue(PostcodeValidator.isValid("AR1"))
        XCTAssertTrue(PostcodeValidator.isValid("ARA"))
        
        XCTAssertTrue(PostcodeValidator.isValid("AB1"))
        XCTAssertTrue(PostcodeValidator.isValid("AB1A"))
        XCTAssertTrue(PostcodeValidator.isValid("AB11"))
        XCTAssertTrue(PostcodeValidator.isValid("ABR"))
        XCTAssertTrue(PostcodeValidator.isValid("ABRA"))
        XCTAssertTrue(PostcodeValidator.isValid("ABR7"))
        
        // The example shown in the user interface
        XCTAssertTrue(PostcodeValidator.isValid("CE1B"))
        
        // The examples given in the validation error message
        XCTAssertTrue(PostcodeValidator.isValid("PO30"))
        XCTAssertTrue(PostcodeValidator.isValid("E2"))
        XCTAssertTrue(PostcodeValidator.isValid("M1"))
        XCTAssertTrue(PostcodeValidator.isValid("EH1"))
        XCTAssertTrue(PostcodeValidator.isValid("L36"))

        XCTAssertFalse(PostcodeValidator.isValid("1A"))
        XCTAssertFalse(PostcodeValidator.isValid("AAA"))
        XCTAssertFalse(PostcodeValidator.isValid("A1A-"))
        // The server will reject lowercase.
        XCTAssertFalse(PostcodeValidator.isValid("aa"))
        
        XCTAssertFalse(PostcodeValidator.isValid(""))
        XCTAssertFalse(PostcodeValidator.isValid("A"))
        XCTAssertFalse(PostcodeValidator.isValid("AA1AB"))
    }
    
}
