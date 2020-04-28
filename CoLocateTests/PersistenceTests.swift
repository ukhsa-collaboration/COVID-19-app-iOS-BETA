//
//  PersistenceTests.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class PersistenceTests: TestCase {
    
    private var secureRegistrationStorage: SecureRegistrationStorage!
    private var broadcastKeyStorage: SecureBroadcastRotationKeyStorage!
    private var monitor: AppMonitoringDouble!
    private var persistence: Persistence!
    
    override func setUp() {
        super.setUp()
        
        secureRegistrationStorage = SecureRegistrationStorage()
        broadcastKeyStorage = SecureBroadcastRotationKeyStorage()
        monitor = AppMonitoringDouble()
        persistence = Persistence(
            secureRegistrationStorage: secureRegistrationStorage,
            broadcastKeyStorage: broadcastKeyStorage,
            monitor: monitor
        )
    }
    
    func testDiagnosisRawValueZeroIsUnknown() {
        XCTAssertNil(persistence.selfDiagnosis)
    }

    func testDiagnosisIsUnknownWhenDefaultsReset() {
        persistence.selfDiagnosis = SelfDiagnosis(symptoms: [.cough], startDate: Date(), expiryDate: Date())

        let appDomain = Bundle.main.bundleIdentifier
        UserDefaults.standard.removePersistentDomain(forName: appDomain!)

        let diagnosis = persistence.selfDiagnosis
        XCTAssertNil(diagnosis)
    }

    func testDeleteSelfDiagnosisWhenNil() {
        persistence.selfDiagnosis = SelfDiagnosis(symptoms: [.cough], startDate: Date(), expiryDate: Date())
        XCTAssertNotNil(persistence.selfDiagnosis)

        persistence.selfDiagnosis = nil
        XCTAssertNil(persistence.selfDiagnosis)
    }
    
    func testRegistrationIsStored() {
        XCTAssertNil(persistence.registration)

        let id = UUID()
        let secretKey = "secret key".data(using: .utf8)!
        let rotationKey = knownGoodECPublicKey()
        let registration = Registration(id: id, secretKey: secretKey, broadcastRotationKey: rotationKey)
        persistence.registration = registration

        XCTAssertEqual(secureRegistrationStorage.get(), PartialRegistration(id: id, secretKey: secretKey))
        XCTAssertEqual(broadcastKeyStorage.read(), rotationKey)
        XCTAssertEqual(persistence.registration, registration)
    }
    
    func testRegistrationUpdatesTheDelegate() {
        let delegate = PersistenceDelegateDouble()
        persistence.delegate = delegate

        let id = UUID()
        let secretKey = "secret key".data(using: .utf8)!
        let registration = Registration(id: id, secretKey: secretKey, broadcastRotationKey: knownGoodECPublicKey())
        persistence.registration = registration

        XCTAssertEqual(delegate.recordedRegistration, registration)
    }
    
    func testRegistrationReturnsNilIfNoBroadcastKey() throws {
        try secureRegistrationStorage.set(registration: PartialRegistration(id: UUID(), secretKey: Data()))
        try broadcastKeyStorage.clear()
        
        XCTAssertNil(persistence.registration)
    }

    func testPartialPostcodeIsPersisted() {
        let p1 = Persistence(
            secureRegistrationStorage: secureRegistrationStorage,
            broadcastKeyStorage: broadcastKeyStorage,
            monitor: monitor
        )
        let p2 = Persistence(
            secureRegistrationStorage: secureRegistrationStorage,
            broadcastKeyStorage: broadcastKeyStorage,
            monitor: monitor
        )
        
        p1.partialPostcode = nil
        XCTAssertNil(p2.partialPostcode)
        
        p1.partialPostcode = "9810"
        XCTAssertEqual(p2.partialPostcode, "9810")
    }
    
    func testMonitorIsNotifiedWhenPartialPostcodeIsProvided() {
        
        persistence.partialPostcode = nil
        XCTAssertEqual(monitor.detectedEvents, [])
        
        persistence.partialPostcode = "9810"
        XCTAssertEqual(monitor.detectedEvents, [.providedPartialPostcode])
    }

    func testUploadLog() {
        persistence.uploadLog = [UploadLog(event: .started(lastContactEventDate: Date()))]

        XCTAssertFalse(persistence.uploadLog.isEmpty)
    }
}

class PersistenceDelegateDouble: NSObject, PersistenceDelegate {
    var recordedRegistration: Registration?
    func persistence(_ persistence: Persisting, didUpdateRegistration registration: Registration) {
        recordedRegistration = registration
    }
}
