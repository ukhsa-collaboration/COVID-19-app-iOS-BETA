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
    var diagnosis: Diagnosis?
    var enableNewSelfDiagnosis = false

    init(
        allowedDataSharing: Bool = false,
        diagnosis: Diagnosis? = nil,
        registration: Registration? = nil
    ) {
        self.allowedDataSharing = allowedDataSharing
        self.registration = registration
        self.diagnosis = diagnosis
    }

    func clear() {
        allowedDataSharing = false
        diagnosis = nil
        registration = nil
    }
}
