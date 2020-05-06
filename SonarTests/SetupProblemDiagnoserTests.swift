//
//  SetupProblemDiagnoserTests.swift
//  SonarTests
//
//  Created by NHSX on 27/04/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class SetupProblemDiagnoserTests: XCTestCase {
    private let diagnoser = SetupProblemDiagnoser()
    
    func testBluetoothOffProblemIsDetected() {
        for notificationAuthorization in NotificationAuthorizationStatus.allCases {
            let problem = diagnoser.diagnose(
                notificationAuthorization: notificationAuthorization,
                bluetoothAuthorization: .allowed,
                bluetoothStatus: .poweredOff
            )
            
            XCTAssertEqual(problem, .bluetoothOff)
        }
    }
    
    func testBluetoothDeniedProblemDetected() {
        for notificationAuthorization in NotificationAuthorizationStatus.allCases {
            let problem = diagnoser.diagnose(
                notificationAuthorization: notificationAuthorization,
                bluetoothAuthorization: .denied,
                bluetoothStatus: .unauthorized
            )
            
            XCTAssertEqual(problem, .bluetoothPermissions)
        }
    }
    
    func testNotificationDeniedProblemDetectedWhenBluetoothIsFine() {
        let problem = diagnoser.diagnose(
            notificationAuthorization: .denied,
            bluetoothAuthorization: .allowed,
            bluetoothStatus: .poweredOn
        )
        
        XCTAssertEqual(problem, .notificationPermissions)
    }
    
    func testWhenNoProblemsDetected() {
        let problem = diagnoser.diagnose(
            notificationAuthorization: .allowed,
            bluetoothAuthorization: .allowed,
            bluetoothStatus: .poweredOn
        )
        
        XCTAssertNil(problem)
    }
}
