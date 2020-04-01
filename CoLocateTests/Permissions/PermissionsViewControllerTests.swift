//
//  PermissionsViewControllerTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class PermissionsViewControllerTests: TestCase {

    func testPermissionsFlow() {
        let authManagerDouble = AuthorizationManagerDouble()
        let notificationManagerDouble = PushNotificationManagerDouble()
        let persistence = PersistenceDouble()
        let vc = PermissionsViewController.instantiate()
        vc.authManager = authManagerDouble
        vc.notificationManager = notificationManagerDouble
        vc.persistence = persistence
        vc.uiQueue = QueueDouble()

        let permissionsUnwinder = PermissionsUnwinder()
        rootViewController.viewControllers = [permissionsUnwinder]
        permissionsUnwinder.present(vc, animated: false)

        vc.didTapContinue(UIButton())

        // We skip Bluetooth on the simulator and jump straight
        // to requesting notification authorization.
        XCTAssertNotNil(notificationManagerDouble.completion)

        notificationManagerDouble.completion!(.success(true))

        XCTAssert(permissionsUnwinder.didUnwindFromPermissions)
    }

}

class PermissionsUnwinder: UIViewController {
    var didUnwindFromPermissions = false
    @IBAction func unwindFromPermissions(unwindSegue: UIStoryboardSegue) {
        print(#function)
        didUnwindFromPermissions = true
    }
}
