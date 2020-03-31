//
//  PersistanceDouble.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
@testable import CoLocate

class PersistanceDouble: Persistance {

    init(
        diagnosis: Diagnosis = .unknown,
        registration: Registration? = nil
    ) {
        super.init(secureRegistrationStorage: SecureRegistrationStorage.shared)

        self.diagnosis = diagnosis
        self.registration = registration
    }

    private var _diagnosis = Diagnosis.unknown
    override var diagnosis: Diagnosis {
        get { _diagnosis }
        set { _diagnosis = newValue }
    }

    private var _registration: Registration?
    override var registration: Registration? {
        get { _registration }
        set { _registration = newValue }
    }

}
