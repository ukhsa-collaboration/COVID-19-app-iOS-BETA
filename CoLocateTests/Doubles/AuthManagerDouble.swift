//
//  AuthManagerDouble.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
@testable import CoLocate

class AuthorizationManagerDouble: AuthorizationManager {

    init(
        bluetooth: AuthorizationManager.Status = .notDetermined,
        notifications: AuthorizationManager.Status = .notDetermined
    ) {
        _bluetooth = bluetooth
        _notifications = notifications
    }

    var _bluetooth: AuthorizationManager.Status
    override var bluetooth: AuthorizationManager.Status {
        _bluetooth
    }

    var _notifications: AuthorizationManager.Status
    override var notifications: AuthorizationManager.Status {
        _notifications
    }

}
