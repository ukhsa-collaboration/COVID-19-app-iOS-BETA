//
//  ReferenceCodeViewControllerTests.swift
//  SonarTests
//
//  Created by NHSX on 5/14/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class ReferenceCodeViewControllerTests: XCTestCase {

    func testShowsReferenceCodeWhenNotNil() throws {
        let vc = ReferenceCodeViewController.instantiate()
        vc.inject(result: .success("12345"))
        XCTAssertNotNil(vc.view)

        XCTAssertTrue(vc.errorWrapper.isHidden)
        XCTAssertFalse(vc.referenceCodeWrapper.isHidden)
        XCTAssertEqual(vc.referenceCodeLabel.text, "12345")
    }
    
    func testShowsErrorWhenReferenceCodeNil() throws {
        let vc = ReferenceCodeViewController.instantiate()
        vc.inject(result: .error("foobar"))
        XCTAssertNotNil(vc.view)

        XCTAssertFalse(vc.errorWrapper.isHidden)
        XCTAssertTrue(vc.referenceCodeWrapper.isHidden)
        XCTAssertEqual(vc.referenceCodeError.text, "foobar")
    }
}
