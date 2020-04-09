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
    func register() -> Cancelable {
        return CancelableDouble()
    }
}

class CancelableDouble: Cancelable {
    func cancel() {
    }
}
