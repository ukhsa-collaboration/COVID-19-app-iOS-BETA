//
//  Persistence.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Logging

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
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

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
            guard
                let data = UserDefaults.standard.data(forKey: Keys.selfDiagnosis.rawValue),
                let decoded = try? decoder.decode(SelfDiagnosis.self, from: data)
            else {
                return nil
            }

            return decoded
        }
        set {
            guard let data = try? encoder.encode(newValue) else {
                logger.critical("Unable to encode a self-diagnosis")
                return
            }

            UserDefaults.standard.set(data, forKey: Keys.selfDiagnosis.rawValue)
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
