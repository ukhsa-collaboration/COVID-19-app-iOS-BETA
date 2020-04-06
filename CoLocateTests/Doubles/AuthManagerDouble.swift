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

    init(
        bluetooth: AuthorizationStatus = .notDetermined
    ) {
        self.bluetooth = bluetooth
    }

    var bluetooth: AuthorizationStatus = .notDetermined

    var notificationsCompletion: ((AuthorizationStatus) -> Void)?
    func notifications(completion: @escaping (AuthorizationStatus) -> Void) {
        notificationsCompletion = completion
    }

}
