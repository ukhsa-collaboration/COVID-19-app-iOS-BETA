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

    func testAcceptsTwoToFourCharacters() {
        XCTAssertTrue(PostcodeValidator.isValid("1X"))
        XCTAssertTrue(PostcodeValidator.isValid("1YZ"))
        XCTAssertTrue(PostcodeValidator.isValid("1YZA"))
    }
    
    func testRejectsLessThanTwoCharacters() {
        XCTAssertFalse(PostcodeValidator.isValid(""))
        XCTAssertFalse(PostcodeValidator.isValid("1"))
    }
    
    func testRejectsMoreThanFourCharacters() {
        XCTAssertFalse(PostcodeValidator.isValid("1YZAB"))
    }
        
    func testValidationIsCaseInsensitive() {
        XCTAssertTrue(PostcodeValidator.isValid("1yz"))
    }

}
