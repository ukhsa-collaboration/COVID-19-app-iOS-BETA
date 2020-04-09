//
//  RegistrationServiceDouble.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
@testable import CoLocate

class RegistrationServiceDouble: RegistrationService {
    var lastAttempt: Cancelable?
    
    func register() -> Cancelable {
        lastAttempt = CancelableDouble()
        return lastAttempt!
    }
}

class CancelableDouble: Cancelable {
    func cancel() {
    }
}
