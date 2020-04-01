//
//  ApplicationDouble.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

@testable import CoLocate

class ApplicationDouble: Application {
    var registeredForRemoteNotifications = false
    func registerForRemoteNotifications() {
        registeredForRemoteNotifications = true
    }
}
