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
    
    var allowedDataSharing: Bool = false
    var registration: Registration? = nil
    var potentiallyExposed: Bool = false
    var selfDiagnosis: SelfDiagnosis? = nil
    var enableNewSelfDiagnosis = false
    var partialPostcode: String? = nil
    var enableNewKeyRotation = false
    var bluetoothPermissionRequested: Bool = false

    init(
        allowedDataSharing: Bool = false,
        potentiallyExposed: Bool = false,
        diagnosis: SelfDiagnosis? = nil,
        registration: Registration? = nil,
        partialPostcode: String? = nil,
        bluetoothPermissionRequested: Bool = false
    ) {
        self.allowedDataSharing = allowedDataSharing
        self.registration = registration
        self.potentiallyExposed = potentiallyExposed
        self.selfDiagnosis = diagnosis
        self.partialPostcode = partialPostcode
        self.bluetoothPermissionRequested = bluetoothPermissionRequested
    }

    func clear() {
        allowedDataSharing = false
        selfDiagnosis = nil
        registration = nil
        partialPostcode = nil
    }
}
