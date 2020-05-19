//
//  ApplyForTestViewControllerTests.swift
//  SonarTests
//
//  Created by NHSX on 5/18/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class ApplyForTestViewControllerTests: XCTestCase {
    
    func testIncludesRefCodeInUrlOnceLoaded() {
        let opener = UrlOpenerDouble()
        let linkingIdMgr = LinkingIdManagerDouble()
        let vc = ApplyForTestViewController.instantiate()
        vc.inject(linkingIdManager: linkingIdMgr, uiQueue: QueueDouble(), urlOpener: opener)
        XCTAssertNotNil(vc.view)
        
        linkingIdMgr.fetchCompletion?("abcd-1234")
        vc.applyForTestTapped()
        
        XCTAssertEqual(opener.urls, [ContentURLs.shared.applyForTest(referenceCode: "abcd-1234")])
    }
    
    func testExcludesRefCodeFromUrlWhileLoading() {
        let opener = UrlOpenerDouble()
        let linkingIdMgr = LinkingIdManagerDouble()
        let vc = ApplyForTestViewController.instantiate()
        vc.inject(linkingIdManager: linkingIdMgr, uiQueue: QueueDouble(), urlOpener: opener)
        XCTAssertNotNil(vc.view)
        
        vc.applyForTestTapped()
        
        XCTAssertEqual(opener.urls, [ContentURLs.shared.applyForTest(referenceCode: nil)])
    }

    func testExcludesRefCodeFromUrlOnceLoadingFails() {
        let opener = UrlOpenerDouble()
        let linkingIdMgr = LinkingIdManagerDouble()
        let vc = ApplyForTestViewController.instantiate()
        vc.inject(linkingIdManager: linkingIdMgr, uiQueue: QueueDouble(), urlOpener: opener)
        XCTAssertNotNil(vc.view)
        
        linkingIdMgr.fetchCompletion?(nil)
        vc.applyForTestTapped()
        
        XCTAssertEqual(opener.urls, [ContentURLs.shared.applyForTest(referenceCode: nil)])

    }
}
