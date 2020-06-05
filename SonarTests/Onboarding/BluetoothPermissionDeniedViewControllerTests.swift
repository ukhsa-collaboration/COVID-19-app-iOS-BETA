//
//  BluetoothPermissionDeniedViewControllerTests.swift
//  SonarTests
//
//  Created by NHSX on 4/21/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class BluetoothPermissionDeniedViewControllerTests: TestCase {

    func testCallsCompletionCallbackWhenAppBecomesActive() {
        let notificationCenter = NotificationCenter()
        let uiQueue = QueueDouble()
        let vc = BluetoothDeniedViewController.instantiate()
        var called = false
        vc.inject(notificationCenter: notificationCenter, uiQueue: uiQueue) {
            called = true
        }
        XCTAssertNotNil(vc.view)
        
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        
        XCTAssertTrue(called)
    }
}
