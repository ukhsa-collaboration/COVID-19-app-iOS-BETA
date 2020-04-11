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
    init() {
        super.init(
            container: ViewControllerContainerDouble(),
            persistence: Persistence(),
            registrationService: RegistrationServiceDouble()
        )
    }

    var updateCalled = false
    override func update() {
        updateCalled = true
    }
}
