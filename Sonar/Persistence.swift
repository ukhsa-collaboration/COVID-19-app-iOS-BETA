//
//  Persistence.swift
//  Sonar
//
//  Created by NHSX on 18.03.20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Logging

struct HMACKey: Equatable, Codable {
    let data: Data
}

struct Registration: Equatable {
    let sonarId: UUID
    let secretKey: HMACKey
    let broadcastRotationKey: SecKey
}

protocol Persisting {
    var delegate: PersistenceDelegate? { get nonmutating set }

    var registration: Registration? { get nonmutating set }
    var partialPostcode: String? { get nonmutating set }
    var bluetoothPermissionRequested: Bool { get nonmutating set }
    var uploadLog: [UploadLog] { get nonmutating set }
    var lastInstalledVersion: String? { get nonmutating set }
    var lastInstalledBuildNumber: String? { get nonmutating set }
    var disabledNotificationsStatusView: Bool { get nonmutating set }
    var acknowledgmentUrls: Set<URL> { get nonmutating set }
    var statusState: StatusState { get nonmutating set }

    func clear()
}

protocol PersistenceDelegate: class {
    func persistence(_ persistence: Persisting, didUpdateRegistration registration: Registration)
}

class Persistence: Persisting {

    enum Keys: String, CaseIterable {
        case partialPostcode
        case bluetoothPermissionRequested
        case uploadLog
        case linkingId // Should be used only to delete old data
        case lastInstalledBuildNumber
        case lastInstalledVersion
        case acknowledgmentUrls
        case statusState
        case disabledNotificationsStatusView
    }
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let secureRegistrationStorage: SecureRegistrationStorage
    private let broadcastKeyStorage: BroadcastRotationKeyStorage
    private let monitor: AppMonitoring

    weak var delegate: PersistenceDelegate?
    
    init(
        secureRegistrationStorage: SecureRegistrationStorage,
        broadcastKeyStorage: BroadcastRotationKeyStorage,
        monitor: AppMonitoring,
        storageChecker: StorageChecking
    ) {
        self.secureRegistrationStorage = secureRegistrationStorage
        self.broadcastKeyStorage = broadcastKeyStorage
        self.monitor = monitor
        
        let storageState = storageChecker.state
        if storageState == .keyChainAndUserDefaultsOutOfSync {
            clear()
        }
        
        if storageState != .inSync {
            storageChecker.markAsSynced()
        }
        
        // We used to store the user's linking ID, but now we don't.
        // Since it's potentially sensitive, delete it.
        UserDefaults.standard.removeObject(forKey: Keys.linkingId.rawValue)
    }

    var registration: Registration? {
        get {
            guard let partial = secureRegistrationStorage.get() else { return nil }
            guard let broadcastRotationKey = broadcastKeyStorage.read() else {
                logger.error("Ignoring the existing registration because there is no broadcast roation key")
                return nil
            }
                        
            return Registration(sonarId: partial.sonarId, secretKey: partial.secretKey, broadcastRotationKey: broadcastRotationKey)
        }
        
        set {
            guard let registration = newValue else {
                try! secureRegistrationStorage.clear()
                return
            }

            let partial = PartialRegistration(sonarId: registration.sonarId, secretKey: registration.secretKey)
            try! secureRegistrationStorage.set(registration: partial)
            try! broadcastKeyStorage.save(publicKey: registration.broadcastRotationKey)

            delegate?.persistence(self, didUpdateRegistration: registration)
            monitor.report(.registrationSucceeded)
        }
    }

    var partialPostcode: String? {
        get { UserDefaults.standard.string(forKey: Keys.partialPostcode.rawValue) }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.partialPostcode.rawValue)
            if newValue != nil {
                monitor.report(.partialPostcodeProvided)
            }
        }
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
            guard let data = try? encoder.encode(newValue.suffix(100)) else {
                logger.critical("Unable to encode the upload log")
                return
            }

            UserDefaults.standard.set(data, forKey: Keys.uploadLog.rawValue)
        }
    }
    
    var bluetoothPermissionRequested: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.bluetoothPermissionRequested.rawValue) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.bluetoothPermissionRequested.rawValue) }
    }

    var lastInstalledVersion: String? {
        get { UserDefaults.standard.string(forKey: Keys.lastInstalledVersion.rawValue) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.lastInstalledVersion.rawValue) }
    }

    var lastInstalledBuildNumber: String? {
        get { UserDefaults.standard.string(forKey: Keys.lastInstalledBuildNumber.rawValue) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.lastInstalledBuildNumber.rawValue) }
    }
    
    var disabledNotificationsStatusView: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.disabledNotificationsStatusView.rawValue) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.disabledNotificationsStatusView.rawValue) }
    }

    var acknowledgmentUrls: Set<URL> {
        get {
            guard
                let data = UserDefaults.standard.data(forKey: Keys.acknowledgmentUrls.rawValue),
                let decoded = try? decoder.decode(Set<URL>.self, from: data)
            else {
                return []
            }

            return decoded
        }
        set {
            guard let data = try? encoder.encode(newValue.suffix(100)) else {
                logger.critical("Unable to encode the upload log")
                return
            }

            UserDefaults.standard.set(data, forKey: Keys.acknowledgmentUrls.rawValue)
        }
    }

    var statusState: StatusState {
        get {
            guard
                let data = UserDefaults.standard.data(forKey: Keys.statusState.rawValue),
                let decoded = try? decoder.decode(StatusState.self, from: data)
            else {
                let migration = StatusStateMigration()

                let selfDiagnosis = UserDefaults.standard.data(forKey: "selfDiagnosis").flatMap {
                    try? decoder.decode(SelfDiagnosis.self, from: $0)
                }

                let potentiallyExposedOn = UserDefaults.standard.object(forKey: "potentiallyExposed") as? Date

                let migratedStatusState = migration.migrate(diagnosis: selfDiagnosis, potentiallyExposedOn: potentiallyExposedOn)

                // Finish the migration by saving the status state and removing the old data
                self.statusState = migratedStatusState
                UserDefaults.standard.removeObject(forKey: "selfDiagnosis")
                UserDefaults.standard.removeObject(forKey: "potentiallyExposed")

                return migratedStatusState
            }

            return decoded
        }
        set {
            guard let data = try? encoder.encode(newValue) else {
                logger.critical("Unable to encode the status state")
                return
            }

            UserDefaults.standard.set(data, forKey: Keys.statusState.rawValue)
        }
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
