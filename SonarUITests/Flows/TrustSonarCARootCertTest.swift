//
//  TrustSonarCARootCert.swift
//  SonarUITests
//
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest

class TrustSonarCARootCertTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
    }
    
    // This is only run as part of bin/pact-setup
    // or if the PACT_SETUP swift flag is enabled
    #if targetEnvironment(simulator) && PACT_SETUP
    func testTrustSonarCARootCert() {
        let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        
        settings.terminate()
        settings.activate()
        XCTAssertTrue(settings.wait(for: .runningForeground, timeout: 120))
        
        settings.staticTexts["General"].tap()
        settings.cells["About"].tap()
        settings.cells["Certificate Trust Settings"].tap()
        let cell = settings.cells.containing(.staticText, identifier: "Sonar CA")
        let toggle = cell.switches.firstMatch
        if toggle.value as? String != "1" {
            toggle.tap()
            settings.buttons["Continue"].tap()
        }
    }
    #endif
}
