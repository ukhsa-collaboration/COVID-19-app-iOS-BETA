//
//  Persistence.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

enum Diagnosis: Int, CaseIterable {
    case unknown, notInfected, infected, potential
}

protocol PersistenceDelegate: class {
    func persistence(_ persistence: Persistence, didRecordDiagnosis diagnosis: Diagnosis)
}

class Persistence {

    enum Keys: String, CaseIterable {
        case allowedDataSharing
        case diagnosis
    }

    static var shared = Persistence()

    let secureRegistrationStorage: SecureRegistrationStorage
    weak var delegate: PersistenceDelegate?

    var allowedDataSharing: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.allowedDataSharing.rawValue) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.allowedDataSharing.rawValue) }
    }

    var registration: Registration? {
        get { try! secureRegistrationStorage.get() }
        set {
            guard let registration = newValue else {
                try! secureRegistrationStorage.clear()
                return
            }

            try! secureRegistrationStorage.set(registration: registration)
        }
    }

    var diagnosis: Diagnosis {
        get {
            // This force unwrap is deliberate, we should never store an unknown rawValue
            // and I want to fail fast if we somehow do. Note integer(forKey:) returns 0
            // if the key does not exist, which will inflate to .unknown
            return Diagnosis(rawValue: UserDefaults.standard.integer(forKey: Keys.diagnosis.rawValue))!
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Keys.diagnosis.rawValue)
            delegate?.persistence(self, didRecordDiagnosis: diagnosis)
        }
    }

    var newOnboarding: Bool {
        get { true } // UserDefaults.standard.bool(forKey: #function) }
        set { UserDefaults.standard.set(newValue, forKey: #function) }
    }

    init(secureRegistrationStorage: SecureRegistrationStorage) {
        self.secureRegistrationStorage = secureRegistrationStorage
    }

    convenience init() {
        self.init(secureRegistrationStorage: SecureRegistrationStorage.shared)
    }

    func clear() {
        for key in Keys.allCases {
            UserDefaults.standard.removeObject(forKey: key.rawValue)
        }

        try! secureRegistrationStorage.clear()
    }

}
