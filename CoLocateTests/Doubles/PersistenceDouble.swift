//
//  PersistenceDouble.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
@testable import Sonar

class PersistenceDouble: Persisting {
    var delegate: PersistenceDelegate?

    var registration: Registration?
    var potentiallyExposed: Date?
    var selfDiagnosis: SelfDiagnosis?
    var partialPostcode: String?
    var bluetoothPermissionRequested: Bool
    var uploadLog: [UploadLog]
    var linkingId: LinkingId?

    init(
        potentiallyExposed: Date? = nil,
        diagnosis: SelfDiagnosis? = nil,
        registration: Registration? = nil,
        partialPostcode: String? = nil,
        bluetoothPermissionRequested: Bool = false,
        uploadLog: [UploadLog] = [],
        linkingId: LinkingId? = nil
    ) {
        self.registration = registration
        self.potentiallyExposed = potentiallyExposed
        self.selfDiagnosis = diagnosis
        self.partialPostcode = partialPostcode
        self.potentiallyExposed = potentiallyExposed
        self.bluetoothPermissionRequested = bluetoothPermissionRequested
        self.uploadLog = uploadLog
        self.linkingId = linkingId
    }

    func clear() {
        selfDiagnosis = nil
        registration = nil
        partialPostcode = nil
        potentiallyExposed = nil
        bluetoothPermissionRequested = false
        uploadLog = []
        linkingId = nil
    }
}
