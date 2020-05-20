//
//  ApplyForTestContainerViewControllerTests.swift
//  SonarTests
//
//  Created by NHSX on 5/19/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class ApplyForTestContainerViewControllerTests: XCTestCase {

    func testLoadsLinkingId() throws {
        let linkingIdMgr = LinkingIdManagerDouble()
        let vc = ApplyForTestContainerViewController.instantiate()
        vc.inject(linkingIdManager: linkingIdMgr, uiQueue: QueueDouble())
        
        XCTAssertNotNil(vc.view)
        vc.viewDidAppear(false)
        
        XCTAssertNotNil(linkingIdMgr.fetchCompletion)
        XCTAssertEqual(vc.children.count, 1)
        XCTAssertNotNil(vc.children.first as? ReferenceCodeLoadingViewController)
    }

    func testShowsTestingInfoOnSuccess() throws {
        let linkingIdMgr = LinkingIdManagerDouble()
        let vc = ApplyForTestContainerViewController.instantiate()
        vc.inject(linkingIdManager: linkingIdMgr, uiQueue: QueueDouble())
        
        XCTAssertNotNil(vc.view)
        vc.viewDidAppear(false)
        linkingIdMgr.fetchCompletion?("1234-abcd")
        
        XCTAssertNotNil(linkingIdMgr.fetchCompletion)
        XCTAssertEqual(vc.children.count, 1)
        let applyVc = try XCTUnwrap(vc.children.first as? ApplyForTestViewController)
        let refCodeVc = try XCTUnwrap(applyVc.children.first as? ReferenceCodeViewController)
        XCTAssertFalse(refCodeVc.referenceCodeWrapper.isHidden)
        XCTAssertTrue(refCodeVc.errorWrapper.isHidden)
        XCTAssertEqual(refCodeVc.referenceCodeLabel.text, "1234-abcd")
        XCTAssertEqual(applyVc.applyLinkButton.url, ContentURLs.shared.applyForTest(referenceCode: "1234-abcd"))
    }
    
    func testShowsTestingInfoOnFailure() throws {
        let linkingIdMgr = LinkingIdManagerDouble()
        let vc = ApplyForTestContainerViewController.instantiate()
        vc.inject(linkingIdManager: linkingIdMgr, uiQueue: QueueDouble())

        XCTAssertNotNil(vc.view)
        vc.viewDidAppear(false)
        linkingIdMgr.fetchCompletion?(nil)
        
        XCTAssertNotNil(linkingIdMgr.fetchCompletion)
        XCTAssertEqual(vc.children.count, 1)
        let applyVc = try XCTUnwrap(vc.children.first as? ApplyForTestViewController)
        let refCodeVc = try XCTUnwrap(applyVc.children.first as? ReferenceCodeViewController)
        XCTAssertTrue(refCodeVc.referenceCodeWrapper.isHidden)
        XCTAssertFalse(refCodeVc.errorWrapper.isHidden)
        XCTAssertEqual(applyVc.applyLinkButton.url, ContentURLs.shared.applyForTest(referenceCode: nil))
    }

}
