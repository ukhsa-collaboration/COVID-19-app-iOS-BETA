//
//  AnswerButtonTests.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class AnswerButtonTests: XCTestCase {

    func testScalesImageBasedOnFont() throws {
        let button = AnswerButton()
        button.awakeFromNib()
        
        button.textLabel.font = UIFont.systemFont(ofSize: 34)
        button.updateBasedOnAccessibilityDisplayChanges()
        
        let widthConstraint = try XCTUnwrap(button.imageView.constraints.first { c in
            c.identifier == "ImageWidth"
        })
        
        XCTAssertGreaterThan(widthConstraint.constant, 47.9)
        XCTAssertLessThan(widthConstraint.constant, 48.1)
    }
}
