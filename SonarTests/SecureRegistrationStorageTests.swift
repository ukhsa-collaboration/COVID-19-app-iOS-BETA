//
//  SecureRegistrationStorageTests.swift
//  SonarTests
//
//  Created by NHSX on 3/24/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Security
import XCTest
@testable import Sonar

class SecureRegistrationStorageTests: TestCase {

    let sonarId = UUID(uuidString: "1c8d305e-db93-4ba0-81f4-94c33fd35c7c")!
    let secretKey = SecKey.sampleHMACKey

    func testRoundTrip() throws {
        let storage = SecureRegistrationStorage()

        XCTAssertNil(storage.get())

        try storage.set(registration: PartialRegistration(sonarId: sonarId, secretKey: secretKey))

        let registration = storage.get()
        XCTAssertEqual(registration?.sonarId, sonarId)
        XCTAssertEqual(registration?.secretKey, secretKey)
    }

    func testOverwritesExistingRegistration() throws {
        // Add a registration
        let storage = SecureRegistrationStorage()
        try storage.set(registration: PartialRegistration(sonarId: UUID(), secretKey: secretKey))

        // Add another registration
        try storage.set(registration: PartialRegistration(sonarId: sonarId, secretKey: secretKey))

        // We should have the new registration
        let registration = storage.get()
        XCTAssertEqual(registration?.sonarId, sonarId)
        XCTAssertEqual(registration?.secretKey, secretKey)
    }

    func testDoesNotAffectOtherGenericPasswords() throws {
        // Insert a generic password
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "my account",
            kSecValueData as String: "a password".data(using: .utf8)!,
        ]
        SecItemAdd(addQuery as CFDictionary, nil)

        // Set a registration
        let storage = SecureRegistrationStorage()
        try storage.set(registration: PartialRegistration(sonarId: UUID(), secretKey: secretKey))

        // The original generic password should still be there
        let getQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "my account",
            kSecValueData as String: "a password".data(using: .utf8)!
        ]
        let status = SecItemCopyMatching(getQuery as CFDictionary, nil)
        XCTAssertEqual(status, errSecSuccess)
    }

}
