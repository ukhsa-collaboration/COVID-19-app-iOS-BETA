//
//  AuthManagerDouble.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
@testable import CoLocate

class AuthorizationManagerDouble: AuthorizationManaging {

    var bluetoothCompletion: ((BluetoothAuthorizationStatus) -> Void)?
    var notificationsCompletion: ((NotificationAuthorizationStatus) -> Void)?
    
    var bluetooth: BluetoothAuthorizationStatus
    
    init(bluetooth: BluetoothAuthorizationStatus = .notDetermined) {
        self.bluetooth = bluetooth
    }
    
    func waitForDeterminedBluetoothAuthorizationStatus(completion: @escaping (BluetoothAuthorizationStatus) -> Void) {
        bluetoothCompletion = completion
    }

    func notifications(completion: @escaping (NotificationAuthorizationStatus) -> Void) {
        notificationsCompletion = completion
    }

}
