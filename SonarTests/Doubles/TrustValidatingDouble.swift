//
//  TrustValidatingDouble.swift
//  SonarTests
//
//  Created by NHSX on 27/04/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
@testable import Sonar

struct TrustValidatingDouble: TrustValidating {
    var shouldAccept = true
    func canAccept(_ trust: SecTrust?) -> Bool {
        shouldAccept
    }
}
