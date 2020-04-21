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

    var bluetooth: BluetoothAuthorizationStatus
    var notificationsCompletion: ((NotificationAuthorizationStatus) -> Void)?

    init(bluetooth: BluetoothAuthorizationStatus = .notDetermined) {
        self.bluetooth = bluetooth
    }

    func notifications(completion: @escaping (NotificationAuthorizationStatus) -> Void) {
        notificationsCompletion = completion
    }

}
