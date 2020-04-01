//
//  PersistenceDouble.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
@testable import CoLocate

class PersistenceDouble: Persistence {

    init(
        allowedDataSharing: Bool = false,
        diagnosis: Diagnosis = .unknown,
        registration: Registration? = nil,
        newOnboarding: Bool = false
    ) {
        self._allowedDataSharing = allowedDataSharing
        self._registration = registration
        self._diagnosis = diagnosis
        self._newOnboarding = newOnboarding

        super.init(secureRegistrationStorage: SecureRegistrationStorage.shared)
    }

    private var _allowedDataSharing: Bool
    override var allowedDataSharing: Bool {
        get { _allowedDataSharing }
        set { _allowedDataSharing = newValue }
    }

    private var _registration: Registration?
    override var registration: Registration? {
        get { _registration }
        set { _registration = newValue }
    }

    private var _diagnosis: Diagnosis
    override var diagnosis: Diagnosis {
        get { _diagnosis }
        set { _diagnosis = newValue }
    }
    
    private var _newOnboarding: Bool
    override var newOnboarding: Bool {
        get { _newOnboarding }
        set { _newOnboarding = newValue }
    }
}
