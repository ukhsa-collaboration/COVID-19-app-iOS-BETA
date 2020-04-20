//
//  Persistence.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Logging

struct Registration: Equatable {
    let id: UUID
    let secretKey: Data
    // TODO: Make broadcastRotationKey non-optional once the key rotation feature
    // is no longer hidden behind a feature flag.
    let broadcastRotationKey: SecKey?

    init(id: UUID, secretKey: Data, broadcastRotationKey: SecKey?) {
        self.id = id
        self.secretKey = secretKey
        self.broadcastRotationKey = broadcastRotationKey
    }
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

    static var shared = Persistence(secureRegistrationStorage: SecureRegistrationStorage(), broadcastKeyStorage: SecureBroadcastRotationKeyStorage())
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let secureRegistrationStorage: SecureRegistrationStorage
    private let broadcastKeyStorage: BroadcastRotationKeyStorage

    weak var delegate: PersistenceDelegate?
    
    init(secureRegistrationStorage: SecureRegistrationStorage, broadcastKeyStorage: BroadcastRotationKeyStorage) {
        self.secureRegistrationStorage = secureRegistrationStorage
        self.broadcastKeyStorage = broadcastKeyStorage
    }

    var allowedDataSharing: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.allowedDataSharing.rawValue) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.allowedDataSharing.rawValue) }
    }

    var registration: Registration? {
        get {
            guard let partial = try? secureRegistrationStorage.get() else { return nil }
            var broadcastRotationKey: SecKey?
            
            do {
                broadcastRotationKey = try broadcastKeyStorage.read()
            } catch {
                logger.error("Error reading broadcast key: \(error.localizedDescription)")
                return nil
            }
            
            return Registration(id: partial.id, secretKey: partial.secretKey, broadcastRotationKey: broadcastRotationKey)
        }
        
        set {
            guard let registration = newValue else {
                try! secureRegistrationStorage.clear()
                return
            }

            let partial = PartialRegistration(id: registration.id, secretKey: registration.secretKey)
            try! secureRegistrationStorage.set(registration: partial)
            
            if let k = registration.broadcastRotationKey {
                try! broadcastKeyStorage.save(publicKey: k)
            }

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

    func clear() {
        for key in Keys.allCases {
            UserDefaults.standard.removeObject(forKey: key.rawValue)
        }

        try! secureRegistrationStorage.clear()
        try! broadcastKeyStorage.clear()
    }

}

fileprivate let logger = Logger(label: "Persistence")
