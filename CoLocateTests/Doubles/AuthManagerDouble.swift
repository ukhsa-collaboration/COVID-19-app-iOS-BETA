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
        bluetooth: AuthorizationManager.Status = .notDetermined
    ) {
        _bluetooth = bluetooth
    }

    var _bluetooth: AuthorizationManager.Status
    override var bluetooth: AuthorizationManager.Status {
        _bluetooth
    }

    var notificationsCompletion: ((AuthorizationManager.Status) -> Void)?
    override func notifications(completion: @escaping (AuthorizationManager.Status) -> Void) {
        notificationsCompletion = completion
    }

}
