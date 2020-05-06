//
//  AuthorizationManaging.swift
//  Sonar
//
//  Created by NHSX on 06/04/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

enum BluetoothAuthorizationStatus: CaseIterable {
    case notDetermined
    case allowed
    case denied
}

enum NotificationAuthorizationStatus: CaseIterable {
    case notDetermined
    case allowed
    case denied
}

protocol AuthorizationManaging {
    var bluetooth: BluetoothAuthorizationStatus { get }
    func waitForDeterminedBluetoothAuthorizationStatus(completion: @escaping (BluetoothAuthorizationStatus) -> Void)
    func notifications(completion: @escaping (NotificationAuthorizationStatus) -> Void)
}
