//
//  AuthorizationManaging.swift
//  CoLocate
//
//  Created by NHSX.
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
    func notifications(completion: @escaping (NotificationAuthorizationStatus) -> Void)
}
