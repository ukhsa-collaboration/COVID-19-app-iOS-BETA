//
//  StatusViewControllerTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class StatusViewControllerTests: XCTestCase {
    
    func testShowsInitialRegisteredStatus() {
        let vc = StatusViewController.instantiate()
        vc.inject(persistence: PersistenceDouble(registration: arbitraryRegistration()))
        XCTAssertNotNil(vc.view)
        
        XCTAssertEqual(vc.registrationStatusText?.text, "Everything is working OK")
    }
    
    func testShowsInitialInProgressStatus() {
        let vc = StatusViewController.instantiate()
        vc.inject(persistence: PersistenceDouble(registration: nil))
        XCTAssertNotNil(vc.view)
        
        XCTAssertEqual(vc.registrationStatusText?.text, "Finalising setup...")
    }
    
    func arbitraryRegistration() -> Registration {
        return Registration(id: UUID(), secretKey: Data())
    }
}
