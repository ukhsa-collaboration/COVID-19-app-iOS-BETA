//
//  PersistenceDouble.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
@testable import CoLocate

class PersistenceDouble: Persisting {
    var delegate: PersistenceDelegate?

    var registration: Registration? = nil
    var potentiallyExposed: Bool = false
    var selfDiagnosis: SelfDiagnosis? = nil
    var partialPostcode: String? = nil

    init(
        allowedDataSharing: Bool = false,
        potentiallyExposed: Bool = false,
        diagnosis: SelfDiagnosis? = nil,
        registration: Registration? = nil,
        partialPostcode: String? = nil
    ) {
        self.registration = registration
        self.selfDiagnosis = diagnosis
        self.partialPostcode = partialPostcode
        self.potentiallyExposed = potentiallyExposed
    }

    func clear() {
        registration = nil
        selfDiagnosis = nil
        partialPostcode = nil
        potentiallyExposed = false
    }
}
