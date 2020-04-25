//
//  PersistenceTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class PersistenceTests: TestCase {

    func testDiagnosisRawValueZeroIsUnknown() {
        let persistence = Persistence(secureRegistrationStorage: SecureRegistrationStorage(), broadcastKeyStorage: SecureBroadcastRotationKeyStorage())
        XCTAssertNil(persistence.selfDiagnosis)
    }

    func testDiagnosisIsUnknownWhenDefaultsReset() {
        let service = Persistence(secureRegistrationStorage: SecureRegistrationStorage(), broadcastKeyStorage: SecureBroadcastRotationKeyStorage())
        service.selfDiagnosis = SelfDiagnosis(symptoms: [.cough], startDate: Date(), expiryDate: Date())

        let appDomain = Bundle.main.bundleIdentifier
        UserDefaults.standard.removePersistentDomain(forName: appDomain!)

        let diagnosis = service.selfDiagnosis
        XCTAssertNil(diagnosis)
    }

    func testDeleteSelfDiagnosisWhenNil() {
        let service = Persistence(secureRegistrationStorage: SecureRegistrationStorage(), broadcastKeyStorage: SecureBroadcastRotationKeyStorage())
        service.selfDiagnosis = SelfDiagnosis(symptoms: [.cough], startDate: Date(), expiryDate: Date())
        XCTAssertNotNil(service.selfDiagnosis)

        service.selfDiagnosis = nil
        XCTAssertNil(service.selfDiagnosis)
    }
    
    func testRegistrationIsStored() {
        let secureRegistrationStorage = SecureRegistrationStorage()
        let broadcastKeyStorage = SecureBroadcastRotationKeyStorage()
        let persistence = Persistence(secureRegistrationStorage: secureRegistrationStorage, broadcastKeyStorage: broadcastKeyStorage)

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
        let persistence = Persistence(secureRegistrationStorage: SecureRegistrationStorage(), broadcastKeyStorage: SecureBroadcastRotationKeyStorage())
        persistence.delegate = delegate

        let id = UUID()
        let secretKey = "secret key".data(using: .utf8)!
        let registration = Registration(id: id, secretKey: secretKey, broadcastRotationKey: knownGoodECPublicKey())
        persistence.registration = registration

        XCTAssertEqual(delegate.recordedRegistration, registration)
    }
    
    func testRegistrationReturnsNilIfNoBroadcastKey() throws {
        let secureRegistrationStorage = SecureRegistrationStorage()
        let broadcastKeyStorage = SecureBroadcastRotationKeyStorage()
        let persistence = Persistence(secureRegistrationStorage: secureRegistrationStorage, broadcastKeyStorage: broadcastKeyStorage)
        
        try secureRegistrationStorage.set(registration: PartialRegistration(id: UUID(), secretKey: Data()))
        try broadcastKeyStorage.clear()
        
        XCTAssertNil(persistence.registration)
    }

    func testPartialPostcodeIsPersisted() {
        let p1 = Persistence(secureRegistrationStorage: SecureRegistrationStorage(), broadcastKeyStorage: SecureBroadcastRotationKeyStorage())
        let p2 = Persistence(secureRegistrationStorage: SecureRegistrationStorage(), broadcastKeyStorage: SecureBroadcastRotationKeyStorage())
        
        p1.partialPostcode = nil
        XCTAssertNil(p2.partialPostcode)
        
        p1.partialPostcode = "9810"
        XCTAssertEqual(p2.partialPostcode, "9810")
    }

    func testUploadLog() {
        let persistence = Persistence(secureRegistrationStorage: SecureRegistrationStorage(), broadcastKeyStorage: SecureBroadcastRotationKeyStorage())

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
