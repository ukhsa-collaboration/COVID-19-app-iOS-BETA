//
//  Persistence.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Logging

enum SelfDiagnosis: Int, CaseIterable {
    case notInfected = 1, infected
}

protocol Persisting {
    var allowedDataSharing: Bool { get nonmutating set }
    var registration: Registration? { get nonmutating set }
    var potentiallyExposed: Bool { get nonmutating set }
    var selfDiagnosis: SelfDiagnosis? { get nonmutating set }
    var partialPostcode: String? { get nonmutating set }
    var enableNewKeyRotation: Bool { get nonmutating set }
    
    func clear()
}


protocol PersistenceDelegate: class {
    func persistence(_ persistence: Persistence, didUpdateRegistration registration: Registration)
}

class Persistence: Persisting {

    enum Keys: String, CaseIterable {
        case allowedDataSharing
        case potentiallyExposed
        case selfDiagnosis

        // Feature flags
        case newKeyRotation
        case partialPostcode
    }

    static var shared = Persistence()

    let secureRegistrationStorage: SecureRegistrationStorage

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

    var potentiallyExposed: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.potentiallyExposed.rawValue) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.potentiallyExposed.rawValue) }
    }

    var selfDiagnosis: SelfDiagnosis? {
        get {
            let rawDiagnosis = UserDefaults.standard.integer(forKey: Keys.selfDiagnosis.rawValue)

            if rawDiagnosis == 0 {
                return nil
            }

            guard let diagnosis = SelfDiagnosis(rawValue: rawDiagnosis) else {
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

            UserDefaults.standard.set(diagnosis.rawValue, forKey: Keys.selfDiagnosis.rawValue)
        }
    }
    
    var partialPostcode: String? {
        get { UserDefaults.standard.string(forKey: Keys.partialPostcode.rawValue) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.partialPostcode.rawValue) }
    }

    var enableNewKeyRotation: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.newKeyRotation.rawValue) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.newKeyRotation.rawValue) }
    }

    init(secureRegistrationStorage: SecureRegistrationStorage) {
        self.secureRegistrationStorage = secureRegistrationStorage
    }

    convenience init() {
        self.init(secureRegistrationStorage: SecureRegistrationStorage())
    }

    func clear() {
        for key in Keys.allCases {
            UserDefaults.standard.removeObject(forKey: key.rawValue)
        }

        try! secureRegistrationStorage.clear()
    }

}

fileprivate let logger = Logger(label: "Persistence")
