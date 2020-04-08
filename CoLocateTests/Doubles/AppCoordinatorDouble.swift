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
        super.init(rootViewController: RootViewController(),
                   persistence: Persistence())
    }

    override func showAppropriateViewController() {
        showAppropriateViewControllerWasCalled = true
    }
}
