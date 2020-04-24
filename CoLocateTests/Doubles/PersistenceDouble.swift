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

    var registration: Registration?
    var potentiallyExposed: Bool
    var selfDiagnosis: SelfDiagnosis?
    var partialPostcode: String?
    var bluetoothPermissionRequested: Bool = false
    var uploadLog: [UploadLog]

    init(
        potentiallyExposed: Bool = false,
        diagnosis: SelfDiagnosis? = nil,
        registration: Registration? = nil,
        partialPostcode: String? = nil,
        bluetoothPermissionRequested: Bool = false,
        uploadLog: [UploadLog] = []
    ) {
        self.registration = registration
        self.potentiallyExposed = potentiallyExposed
        self.selfDiagnosis = diagnosis
        self.partialPostcode = partialPostcode
        self.potentiallyExposed = potentiallyExposed
        self.bluetoothPermissionRequested = bluetoothPermissionRequested
        self.uploadLog = uploadLog
    }

    func clear() {
        selfDiagnosis = nil
        registration = nil
        partialPostcode = nil
        potentiallyExposed = false
        bluetoothPermissionRequested = false
        uploadLog = []
    }
}
