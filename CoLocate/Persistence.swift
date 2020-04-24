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
    let broadcastRotationKey: SecKey

    init(id: UUID, secretKey: Data, broadcastRotationKey: SecKey) {
        self.id = id
        self.secretKey = secretKey
        self.broadcastRotationKey = broadcastRotationKey
    }
}


protocol Persisting {
    var delegate: PersistenceDelegate? { get set }

    var registration: Registration? { get nonmutating set }
    var potentiallyExposed: Bool { get nonmutating set }
    var selfDiagnosis: SelfDiagnosis? { get nonmutating set }
    var partialPostcode: String? { get nonmutating set }
    var uploadLog: [UploadLog] { get nonmutating set }

    var enableRegistrationReminders: Bool { get nonmutating set }

    func clear()
}

protocol PersistenceDelegate: class {
    func persistence(_ persistence: Persisting, didUpdateRegistration registration: Registration)
}

class Persistence: Persisting {

    enum Keys: String, CaseIterable {
        case potentiallyExposed
        case selfDiagnosis
        case partialPostcode
        case uploadLog
        case enableRegistrationReminders
    }

    static var shared = Persistence(
        secureRegistrationStorage: SecureRegistrationStorage(),
        broadcastKeyStorage: SecureBroadcastRotationKeyStorage()
    )
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let secureRegistrationStorage: SecureRegistrationStorage
    private let broadcastKeyStorage: BroadcastRotationKeyStorage

    weak var delegate: PersistenceDelegate?
    
    init(secureRegistrationStorage: SecureRegistrationStorage, broadcastKeyStorage: BroadcastRotationKeyStorage) {
        self.secureRegistrationStorage = secureRegistrationStorage
        self.broadcastKeyStorage = broadcastKeyStorage
    }

    var registration: Registration? {
        get {
            guard let partial = secureRegistrationStorage.get() else { return nil }
            guard let broadcastRotationKey = broadcastKeyStorage.read() else {
                logger.error("Ignoring the existing registration because there is no broadcast roation key")
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
            try! broadcastKeyStorage.save(publicKey: registration.broadcastRotationKey)

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
            guard let newValue = newValue else {
                UserDefaults.standard.removeObject(forKey: Keys.selfDiagnosis.rawValue)
                return
            }

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

    var uploadLog: [UploadLog] {
        get {
            guard
                let data = UserDefaults.standard.data(forKey: Keys.uploadLog.rawValue),
                let decoded = try? decoder.decode([UploadLog].self, from: data)
            else {
                return []
            }

            return decoded
        }
        set {
            guard let data = try? encoder.encode(newValue) else {
                logger.critical("Unable to encode the upload log")
                return
            }

            UserDefaults.standard.set(data, forKey: Keys.uploadLog.rawValue)
        }
    }
    
    var enableRegistrationReminders: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.enableRegistrationReminders.rawValue) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.enableRegistrationReminders.rawValue) }
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
