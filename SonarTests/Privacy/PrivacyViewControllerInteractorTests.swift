//
//  PrivacyViewControllerInteractorTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import XCTest
@testable import CoLocate

class PrivacyViewControllerInteractorTests: XCTestCase {
    
    private var persistence: Persisting!
    private var interactor: PrivacyViewControllerInteractor!
    
    override func setUp() {
        super.setUp()
        
        persistence = PersistenceDouble(
            allowedDataSharing: false
        )
        interactor = PrivacyViewControllerInteractor(persistence: persistence)
    }
    
    func testPersistentIsUpdatedWhenAllowingDataSharing() {
        interactor.allowDataSharing {}
        XCTAssert(persistence.allowedDataSharing)
    }
    
    func testCompletionIsCalledAfterAllowingDataSharing() {
        var callbackCount = 0
        interactor.allowDataSharing {
            callbackCount += 1
        }
        
        XCTAssertEqual(callbackCount, 1)
    }
    
}

