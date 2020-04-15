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
    
    var allowedDataSharing: Bool
    var registration: Registration?
    var selfDiagnosis: SelfDiagnosis?
    var enableNewSelfDiagnosis = false
    var partialPostcode: String?
    var enableNewKeyRotation = false

    init(
        allowedDataSharing: Bool = false,
        diagnosis: SelfDiagnosis? = nil,
        registration: Registration? = nil,
        partialPostcode: String? = nil
    ) {
        self.allowedDataSharing = allowedDataSharing
        self.registration = registration
        self.selfDiagnosis = diagnosis
        self.partialPostcode = partialPostcode
    }

    func clear() {
        allowedDataSharing = false
        selfDiagnosis = nil
        registration = nil
        partialPostcode = nil
    }
}
