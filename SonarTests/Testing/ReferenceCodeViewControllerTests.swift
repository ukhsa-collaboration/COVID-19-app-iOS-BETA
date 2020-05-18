//
//  LinkingIdViewControllerTests.swift
//  SonarTests
//
//  Created by NHSX on 5/14/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class ReferenceCodeViewControllerTests: XCTestCase {

    func testFetches() {
        let mgr = LinkingIdManagerDouble()
        let vc = ReferenceCodeViewController.instantiate()
        vc.inject(linkingIdManager: mgr, uiQueue: QueueDouble())
        XCTAssertNotNil(vc.view)
        
        XCTAssertFalse(vc.fetchingWrapper.isHidden)
        XCTAssertTrue(vc.errorWrapper.isHidden)
        XCTAssertTrue(vc.referenceCodeWrapper.isHidden)
        XCTAssertNotNil(mgr.fetchCompletion)
    }
    
    func testHandlesSuccess() throws {
        let mgr = LinkingIdManagerDouble()
        let vc = ReferenceCodeViewController.instantiate()
        vc.inject(linkingIdManager: mgr, uiQueue: QueueDouble())
        XCTAssertNotNil(vc.view)

        let completion = try XCTUnwrap(mgr.fetchCompletion)
        completion("12345")
        
        XCTAssertTrue(vc.fetchingWrapper.isHidden)
        XCTAssertTrue(vc.errorWrapper.isHidden)
        XCTAssertFalse(vc.referenceCodeWrapper.isHidden)
        XCTAssertEqual(vc.referenceCodeLabel.text, "12345")
    }
    
    func testHandlesFailure() throws {
        let mgr = LinkingIdManagerDouble()
        let vc = ReferenceCodeViewController.instantiate()
        vc.inject(linkingIdManager: mgr, uiQueue: QueueDouble())
        XCTAssertNotNil(vc.view)

        let completion = try XCTUnwrap(mgr.fetchCompletion)
        completion(nil)
        
        XCTAssertTrue(vc.fetchingWrapper.isHidden)
        XCTAssertFalse(vc.errorWrapper.isHidden)
        XCTAssertTrue(vc.referenceCodeWrapper.isHidden)
    }
}
