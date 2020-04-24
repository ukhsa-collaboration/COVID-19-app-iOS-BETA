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
    var uploadLog: [UploadLog]

    init(
        potentiallyExposed: Bool = false,
        diagnosis: SelfDiagnosis? = nil,
        registration: Registration? = nil,
        partialPostcode: String? = nil,
        uploadLog: [UploadLog] = []
    ) {
        self.registration = registration
        self.selfDiagnosis = diagnosis
        self.partialPostcode = partialPostcode
        self.potentiallyExposed = potentiallyExposed
        self.uploadLog = uploadLog
    }

    func clear() {
        registration = nil
        selfDiagnosis = nil
        partialPostcode = nil
        potentiallyExposed = false
        uploadLog = []
    }
}
