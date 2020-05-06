//
//  RegistrationServiceDouble.swift
//  SonarTests
//
//  Created by NHSX on 3/27/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
@testable import Sonar

class RegistrationServiceDouble: RegistrationService {
    var registerCalled = false
    
    func register() {
        registerCalled = true
    }
}
