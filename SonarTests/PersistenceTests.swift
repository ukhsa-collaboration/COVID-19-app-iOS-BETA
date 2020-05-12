//
//  PersistenceTests.swift
//  SonarTests
//
//  Created by NHSX on 18.03.20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class PersistenceTests: TestCase {
    
    private var secureRegistrationStorage: SecureRegistrationStorage!
    private var broadcastKeyStorage: SecureBroadcastRotationKeyStorage!
    private var monitor: AppMonitoringDouble!
    private var storageChecker: StorageCheckingDouble!
    private var persistence: Persistence!
    
    override func setUp() {
        super.setUp()
        
        secureRegistrationStorage = SecureRegistrationStorage()
        broadcastKeyStorage = SecureBroadcastRotationKeyStorage()
        monitor = AppMonitoringDouble()
        storageChecker = StorageCheckingDouble()
        persistence = Persistence(
            secureRegistrationStorage: secureRegistrationStorage,
            broadcastKeyStorage: broadcastKeyStorage,
            monitor: monitor,
            storageChecker: storageChecker
        )
    }
    
    func testDiagnosisRawValueZeroIsUnknown() {
        XCTAssertNil(persistence.selfDiagnosis)
    }

    func testDiagnosisIsUnknownWhenDefaultsReset() {
        persistence.selfDiagnosis = SelfDiagnosis(type: .initial, symptoms: [.cough], startDate: Date())

        let appDomain = Bundle.main.bundleIdentifier
        UserDefaults.standard.removePersistentDomain(forName: appDomain!)

        let diagnosis = persistence.selfDiagnosis
        XCTAssertNil(diagnosis)
    }

    func testDeleteSelfDiagnosisWhenNil() {
        persistence.selfDiagnosis = SelfDiagnosis(type: .initial, symptoms: [.cough], startDate: Date())
        XCTAssertNotNil(persistence.selfDiagnosis)

        persistence.selfDiagnosis = nil
        XCTAssertNil(persistence.selfDiagnosis)
    }
    
    func testRegistrationIsStored() {
        XCTAssertNil(persistence.registration)

        let sonarId = UUID()
        let secretKey = SecKey.sampleHMACKey
        let rotationKey = SecKey.sampleEllipticCurveKey
        let registration = Registration(sonarId: sonarId, secretKey: secretKey, broadcastRotationKey: rotationKey)
        persistence.registration = registration

        XCTAssertEqual(secureRegistrationStorage.get(), PartialRegistration(sonarId: sonarId, secretKey: secretKey))
        XCTAssertEqual(broadcastKeyStorage.read(), rotationKey)
        XCTAssertEqual(persistence.registration, registration)
    }
    
    func testRegistrationUpdatesTheDelegate() {
        let delegate = PersistenceDelegateDouble()
        persistence.delegate = delegate

        let id = UUID()
        let secretKey = SecKey.sampleHMACKey
        let registration = Registration(sonarId: id, secretKey: secretKey, broadcastRotationKey: SecKey.sampleEllipticCurveKey)
        persistence.registration = registration

        XCTAssertEqual(delegate.recordedRegistration, registration)
    }
    
    func testRegistrationReturnsNilIfNoBroadcastKey() throws {
        try secureRegistrationStorage.set(registration: PartialRegistration(sonarId: UUID(), secretKey: SecKey.sampleHMACKey))
        try broadcastKeyStorage.clear()
        
        XCTAssertNil(persistence.registration)
    }

    func testPartialPostcodeIsPersisted() {
        let p1 = Persistence(
            secureRegistrationStorage: secureRegistrationStorage,
            broadcastKeyStorage: broadcastKeyStorage,
            monitor: monitor,
            storageChecker: StorageCheckingDouble()
        )
        let p2 = Persistence(
            secureRegistrationStorage: secureRegistrationStorage,
            broadcastKeyStorage: broadcastKeyStorage,
            monitor: monitor,
            storageChecker: StorageCheckingDouble()
        )
        
        p1.partialPostcode = nil
        XCTAssertNil(p2.partialPostcode)
        
        p1.partialPostcode = "9810"
        XCTAssertEqual(p2.partialPostcode, "9810")
    }
    
    func testUploadLog() {
        persistence.uploadLog = [UploadLog(event: .started(lastContactEventDate: Date()))]

        XCTAssertFalse(persistence.uploadLog.isEmpty)
    }

    func testUploadLogTruncates() {
        persistence.uploadLog = (0..<101).map { _ in UploadLog(event: .started(lastContactEventDate: Date())) }

        XCTAssertEqual(persistence.uploadLog.count, 100)
    }
    
    func testMonitorIsNotifiedWhenPartialPostcodeIsProvided() {
        
        persistence.partialPostcode = nil
        XCTAssertEqual(monitor.detectedEvents, [])
        
        persistence.partialPostcode = "9810"
        XCTAssertEqual(monitor.detectedEvents, [.partialPostcodeProvided])
    }
    
    func testLastInstalledVersionNumberIsPersisted() {
        let p1 = Persistence(
            secureRegistrationStorage: secureRegistrationStorage,
            broadcastKeyStorage: broadcastKeyStorage,
            monitor: monitor,
            storageChecker: StorageCheckingDouble()
        )
        let p2 = Persistence(
            secureRegistrationStorage: secureRegistrationStorage,
            broadcastKeyStorage: broadcastKeyStorage,
            monitor: monitor,
            storageChecker: StorageCheckingDouble()
        )
        
        p1.lastInstalledVersion = nil
        XCTAssertNil(p2.lastInstalledVersion)
        
        p1.lastInstalledVersion = "1.2.3"
        XCTAssertEqual(p2.lastInstalledVersion, "1.2.3")
    }
    
    func testLastInstalledBuildNumberIsPersisted() {
        let p1 = Persistence(
            secureRegistrationStorage: secureRegistrationStorage,
            broadcastKeyStorage: broadcastKeyStorage,
            monitor: monitor,
            storageChecker: StorageCheckingDouble()
        )
        let p2 = Persistence(
            secureRegistrationStorage: secureRegistrationStorage,
            broadcastKeyStorage: broadcastKeyStorage,
            monitor: monitor,
            storageChecker: StorageCheckingDouble()
        )
        
        p1.lastInstalledBuildNumber = nil
        XCTAssertNil(p2.lastInstalledBuildNumber)
        
        p1.lastInstalledBuildNumber = "42"
        XCTAssertEqual(p2.lastInstalledBuildNumber, "42")
    }

    func testMonitorIsNotifiedWhenRegistrationSucceeds() {
        persistence.registration = nil
        XCTAssertEqual(monitor.detectedEvents, [])
        
        let id = UUID()
        let secretKey = SecKey.sampleHMACKey
        persistence.registration = Registration(sonarId: id, secretKey: secretKey, broadcastRotationKey: SecKey.sampleEllipticCurveKey)
        XCTAssertEqual(monitor.detectedEvents, [.registrationSucceeded])
    }

    func testAcknowledgmentUrls() {
        persistence.acknowledgmentUrls = [URL(string: "https://example.com/ack")!]

        XCTAssertEqual(persistence.acknowledgmentUrls, [URL(string: "https://example.com/ack")!])
    }

    func testAcknowledgmentUrlsTruncates() {
        persistence.acknowledgmentUrls = Set((0..<101).map { URL(string: "https://example.com/ack/\($0)")! })

        XCTAssertEqual(persistence.acknowledgmentUrls.count, 100)
    }
    
    func testMarksAnUninitializedStorageAsSynchronised() {
        storageChecker.state = .notInitialized
        persistence.partialPostcode = "AB12"
        recreatePersistence()
        XCTAssertEqual(storageChecker.markAsSyncedCallbackCount, 1)
        XCTAssertEqual(persistence.partialPostcode, "AB12")
    }
    
    func testAnInSyncStorageIsNotReSynchronised() {
        storageChecker.state = .inSync
        persistence.partialPostcode = "AB12"
        recreatePersistence()
        XCTAssertEqual(storageChecker.markAsSyncedCallbackCount, 0)
        XCTAssertEqual(persistence.partialPostcode, "AB12")
    }
    
    func testAnOutOfSyncStorageIsResetAndSynchronized() {
        storageChecker.state = .keyChainAndUserDefaultsOutOfSync
        persistence.partialPostcode = "AB12"
        recreatePersistence()
        XCTAssertEqual(storageChecker.markAsSyncedCallbackCount, 1)
        XCTAssertNil(persistence.partialPostcode)
    }
    
    func testDeletesLinkingId() {
        UserDefaults.standard.set("the linking ID", forKey: "linkingId")
        recreatePersistence()
        XCTAssertNil(UserDefaults.standard.string(forKey: "linkingId"))
    }

    func testStatusState() {
        persistence.statusState = .ok(StatusState.Ok())
        XCTAssertEqual(persistence.statusState, .ok(StatusState.Ok()))
    }

    func testStatusStateMigration() {
        XCTAssertEqual(persistence.statusState, .ok(StatusState.Ok()))

        let expiryDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let diagnosis = SelfDiagnosis(type: .initial, symptoms: [.cough], startDate: Date(), expiryDate: expiryDate)
        persistence.selfDiagnosis = diagnosis
        persistence.potentiallyExposed = Date()

        XCTAssertEqual(persistence.statusState, .symptomatic(StatusState.Symptomatic(symptoms: [.cough], expiryDate: diagnosis.expiryDate)))
    }
    
    private func recreatePersistence() {
        storageChecker.markAsSyncedCallbackCount = 0
        persistence = Persistence(
            secureRegistrationStorage: secureRegistrationStorage,
            broadcastKeyStorage: broadcastKeyStorage,
            monitor: monitor,
            storageChecker: storageChecker
        )
    }

}

private class PersistenceDelegateDouble: NSObject, PersistenceDelegate {
    var recordedRegistration: Registration?
    func persistence(_ persistence: Persisting, didUpdateRegistration registration: Registration) {
        recordedRegistration = registration
    }
}
