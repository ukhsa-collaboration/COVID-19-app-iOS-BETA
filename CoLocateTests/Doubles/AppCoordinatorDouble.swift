//
//  AppCoordinatorDouble.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
@testable import CoLocate

class AppCoordinatorDouble: AppCoordinator {
    var showAppropriateViewControllerWasCalled = false

    init() {
        super.init(navController: UINavigationController(),
                   diagnosisService: DiagnosisService(),
                   secureRequestFactory: SecureRequestFactoryDouble())
    }

    override func showAppropriateViewController() {
        showAppropriateViewControllerWasCalled = true
    }
}
