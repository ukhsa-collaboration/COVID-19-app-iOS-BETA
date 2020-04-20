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
        service.selfDiagnosis = SelfDiagnosis(symptoms: [.cough], startDate: Date())

        let appDomain = Bundle.main.bundleIdentifier
        UserDefaults.standard.removePersistentDomain(forName: appDomain!)

        let diagnosis = service.selfDiagnosis
        XCTAssertNil(diagnosis)
    }
    
    
    func testRegistrationIsStored() throws {
        let secureRegistrationStorage = SecureRegistrationStorage()
        let broadcastKeyStorage = SecureBroadcastRotationKeyStorage()
        let persistence = Persistence(secureRegistrationStorage: secureRegistrationStorage, broadcastKeyStorage: broadcastKeyStorage)

        XCTAssertNil(persistence.registration)

        let id = UUID()
        let secretKey = "secret key".data(using: .utf8)!
        let rotationKey = knownGoodECPublicKey()
        let registration = Registration(id: id, secretKey: secretKey, broadcastRotationKey: rotationKey)
        persistence.registration = registration

        XCTAssertEqual(try secureRegistrationStorage.get(), PartialRegistration(id: id, secretKey: secretKey))
        XCTAssertEqual(try broadcastKeyStorage.read(), rotationKey)
        XCTAssertEqual(persistence.registration, registration)
    }
    
    func testRegistrationUpdatesTheDelegate() {
        let delegate = PersistenceDelegateDouble()
        let persistence = Persistence(secureRegistrationStorage: SecureRegistrationStorage(), broadcastKeyStorage: SecureBroadcastRotationKeyStorage())
        persistence.delegate = delegate

        let id = UUID()
        let secretKey = "secret key".data(using: .utf8)!
        let registration = Registration(id: id, secretKey: secretKey, broadcastRotationKey: nil)
        persistence.registration = registration

        XCTAssertEqual(delegate.recordedRegistration, registration)
    }

    func testPartialPostcodeIsPersisted() {
        let p1 = Persistence(secureRegistrationStorage: SecureRegistrationStorage(), broadcastKeyStorage: SecureBroadcastRotationKeyStorage())
        let p2 = Persistence(secureRegistrationStorage: SecureRegistrationStorage(), broadcastKeyStorage: SecureBroadcastRotationKeyStorage())
        
        p1.partialPostcode = nil
        XCTAssertNil(p2.partialPostcode)
        
        p1.partialPostcode = "9810"
        XCTAssertEqual(p2.partialPostcode, "9810")
    }
    
    private func knownGoodECPublicKey() -> SecKey {
        let base64EncodedKey = "BDSTjw7/yauS6iyMZ9p5yl6i0n3A7qxYI/3v+6RsHt8o+UrFCyULX3fKZuA6ve+lH1CAItezr+Tk2lKsMcCbHMI="

        let data = Data.init(base64Encoded: base64EncodedKey)!

        let keyDict : [NSObject:NSObject] = [
           kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
           kSecAttrKeyClass: kSecAttrKeyClassPublic,
           kSecAttrKeySizeInBits: NSNumber(value: 256),
           kSecReturnPersistentRef: true as NSObject
        ]

        return SecKeyCreateWithData(data as CFData, keyDict as CFDictionary, nil)!
    }
}

class PersistenceDelegateDouble: NSObject, PersistenceDelegate {
    var recordedRegistration: Registration?
    func persistence(_ persistence: Persistence, didUpdateRegistration registration: Registration) {
        recordedRegistration = registration
    }
}
