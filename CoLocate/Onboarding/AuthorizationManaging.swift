//
//  AuthorizationManaging.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

#warning("Need to split this into two types.")
// Soon, we’ll need to handle all scenarios; but possible cases for notification and bluetooth are not the same.
enum AuthorizationStatus {
    case notDetermined
    case allowed
    case denied
}

protocol AuthorizationManaging {
    var bluetooth: AuthorizationStatus { get }
    func notifications(completion: @escaping (AuthorizationStatus) -> Void)
}
