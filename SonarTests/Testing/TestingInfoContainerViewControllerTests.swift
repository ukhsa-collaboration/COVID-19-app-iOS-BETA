//
//  TestingInfoContainerViewControllerTests.swift
//  SonarTests
//
//  Created by NHSX on 5/18/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class TestingInfoContainerViewControllerTests: XCTestCase {

    let vcProvider: (LinkingIdResult) -> UIViewController = { result in
        let testingInfoVc = TestingInfoViewController.instantiate()
        testingInfoVc.inject(result: result)
        return testingInfoVc
    }

    func testLoadsLinkingId() throws {
        let linkingIdMgr = LinkingIdManagerDouble()
        let vc = TestingInfoContainerViewController.instantiate()
        vc.inject(linkingIdManager: linkingIdMgr, uiQueue: QueueDouble())
        
        XCTAssertNotNil(vc.view)
        vc.viewDidAppear(false)
        
        XCTAssertNotNil(linkingIdMgr.fetchCompletion)
        XCTAssertEqual(vc.children.count, 1)
        XCTAssertNotNil(vc.children.first as? ReferenceCodeLoadingViewController)
    }

    func testShowsTestingInfoOnSuccess() throws {
        let linkingIdMgr = LinkingIdManagerDouble()
        let vc = TestingInfoContainerViewController.instantiate()
        vc.inject(linkingIdManager: linkingIdMgr, uiQueue: QueueDouble(), vcProvider: vcProvider)
        
        XCTAssertNotNil(vc.view)
        vc.viewDidAppear(false)
        linkingIdMgr.fetchCompletion?(.success("1234-abcd"))
        
        XCTAssertNotNil(linkingIdMgr.fetchCompletion)
        XCTAssertEqual(vc.children.count, 1)
        let testingInfoVc = try XCTUnwrap(vc.children.first as? TestingInfoViewController)
        let refCodeVc = try XCTUnwrap(testingInfoVc.children.first as? ReferenceCodeViewController)
        XCTAssertFalse(refCodeVc.referenceCodeWrapper.isHidden)
        XCTAssertTrue(refCodeVc.errorWrapper.isHidden)
        XCTAssertEqual(refCodeVc.referenceCodeLabel.text, "1234-abcd")
    }
    
    func testShowsTestingInfoOnFailure() throws {
        let linkingIdMgr = LinkingIdManagerDouble()
        let vc = TestingInfoContainerViewController.instantiate()
        vc.inject(linkingIdManager: linkingIdMgr, uiQueue: QueueDouble(), vcProvider: vcProvider)
        
        XCTAssertNotNil(vc.view)
        vc.viewDidAppear(false)
        linkingIdMgr.fetchCompletion?(.error("error"))
        
        XCTAssertNotNil(linkingIdMgr.fetchCompletion)
        XCTAssertEqual(vc.children.count, 1)
        let testingInfoVc = try XCTUnwrap(vc.children.first as? TestingInfoViewController)
        let refCodeVc = try XCTUnwrap(testingInfoVc.children.first as? ReferenceCodeViewController)
        XCTAssertTrue(refCodeVc.referenceCodeWrapper.isHidden)
        XCTAssertFalse(refCodeVc.errorWrapper.isHidden)
    }
}
