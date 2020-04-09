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
    var completionHandler: ((Result<(), Error>) -> Void)?
    var lastAttempt: Cancelable?
    
    func register(completionHandler: @escaping ((Result<(), Error>) -> Void)) -> Cancelable {
        self.completionHandler = completionHandler
        lastAttempt = CancelableDouble()
        return lastAttempt!
    }
}

class CancelableDouble: Cancelable {
    func cancel() {
    }
}
