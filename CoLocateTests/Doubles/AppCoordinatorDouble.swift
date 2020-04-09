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
        super.init(rootViewController: RootViewController(),
                   persistence: Persistence())
    }

    var updateCalled = false
    override func update() {
        updateCalled = true
    }
}
