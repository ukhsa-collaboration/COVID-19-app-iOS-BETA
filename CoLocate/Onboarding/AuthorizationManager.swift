//
//  AuthorizationManager.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

class AuthorizationManager {

    enum Status {
        case notDetermined, allowed, denied
    }

    var bluetooth: Status {
        .notDetermined
    }

    func notifications(completion: @escaping (Status) -> Void) {
        completion(.notDetermined)
    }

}
