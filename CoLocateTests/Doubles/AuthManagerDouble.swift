//
//  AuthManagerDouble.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
@testable import CoLocate

class AuthorizationManagerDouble: AuthorizationManaging {

    var bluetooth: AuthorizationStatus
    var notificationsCompletion: ((AuthorizationStatus) -> Void)?

    init(bluetooth: AuthorizationStatus = .notDetermined) {
        self.bluetooth = bluetooth
    }

    func notifications(completion: @escaping (AuthorizationStatus) -> Void) {
        notificationsCompletion = completion
    }

}
