//
//  ScreenTestCase.swift
//  SonarUITests
//
//  Created by NHSX on 03/04/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest

class ScreenTestCase: XCTestCase {
    
    var app: XCUIApplication!
    
    var screen: Screen {
        fatalError("Subclasses must override \(#function)")
    }
    
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
        
        let payload = UITestPayload(screen: screen)
        
        app = XCUIApplication()
        app.launchEnvironment[UITestPayload.environmentVariableName] = try! JSONEncoder().encode(payload).base64EncodedString()
        app.launch()
    }
    
    func eightDaysLater() {
        // close app
        XCUIDevice.shared.press(.home)

        // open app 8 days later
        // (test harness ensures that 8 days pass whenever we close the app)

        XCUIApplication().activate()
        usleep(500000) // wait for app opening animation
    }
}
