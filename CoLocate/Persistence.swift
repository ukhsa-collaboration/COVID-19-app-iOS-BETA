//
//  Persistence.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Logging


protocol PersistenceDelegate: class {
    func persistence(_ persistence: Persistence, didUpdateRegistration registration: Registration)
}

class Persistence: Persisting {

    enum Keys: String, CaseIterable {
        case allowedDataSharing
        case diagnosis

        // Feature flags
        case enableNewSelfDiagnosis
        case newKeyRotation
        case partialPostcode
    }

    static var shared = Persistence()

    let secureRegistrationStorage: SecureRegistrationStorage
    let secureBroadcastRotationKeyStorage: BroadcastRotationKeyStorage

    weak var delegate: PersistenceDelegate?

    var allowedDataSharing: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.allowedDataSharing.rawValue) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.allowedDataSharing.rawValue) }
    }

    var registration: Registration? {
        get { try? secureRegistrationStorage.get() }
        set {
            guard let registration = newValue else {
                try! secureRegistrationStorage.clear()
                return
            }

            try! secureRegistrationStorage.set(registration: registration)

            delegate?.persistence(self, didUpdateRegistration: registration)
        }
    }

    var diagnosis: Diagnosis? {
        get {
            let rawDiagnosis = UserDefaults.standard.integer(forKey: Keys.diagnosis.rawValue)

            if rawDiagnosis == 0 {
                return nil
            }

            guard let diagnosis = Diagnosis(rawValue: rawDiagnosis) else {
                logger.critical("Unable to hydrate a diagnosis from raw: \(rawDiagnosis).")
                return nil
            }

            return diagnosis
        }
        set {
            guard let diagnosis = newValue else {
                logger.critical("Persisting a nil diagnosis - this should never happen!")
                return
            }

            UserDefaults.standard.set(diagnosis.rawValue, forKey: Keys.diagnosis.rawValue)
        }
    }

    var enableNewSelfDiagnosis: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.enableNewSelfDiagnosis.rawValue) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.enableNewSelfDiagnosis.rawValue) }
    }
    
    var partialPostcode: String? {
        get { UserDefaults.standard.string(forKey: Keys.partialPostcode.rawValue) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.partialPostcode.rawValue) }
    }

    var enableNewKeyRotation: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.newKeyRotation.rawValue) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.newKeyRotation.rawValue) }
    }

    init(secureRegistrationStorage: SecureRegistrationStorage, secureBroadcastRotationKeyStorage: BroadcastRotationKeyStorage) {
        self.secureRegistrationStorage = secureRegistrationStorage
        self.secureBroadcastRotationKeyStorage = secureBroadcastRotationKeyStorage
    }

    convenience init() {
        self.init(secureRegistrationStorage: SecureRegistrationStorage(),
                  secureBroadcastRotationKeyStorage: SecureBroadcastRotationKeyStorage.shared)
    }

    func clear() {
        for key in Keys.allCases {
            UserDefaults.standard.removeObject(forKey: key.rawValue)
        }

        try! secureRegistrationStorage.clear()
        try! secureBroadcastRotationKeyStorage.clear()
    }

}

fileprivate let logger = Logger(label: "Persistence")
