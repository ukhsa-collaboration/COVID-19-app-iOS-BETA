//
//  SecureRegistrationStorageTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Security
import XCTest
@testable import CoLocate

class SecureRegistrationStorageTests: XCTestCase {

    let id = UUID(uuidString: "1c8d305e-db93-4ba0-81f4-94c33fd35c7c")!
    let secretKey = "Ik6M9N2CqLv3BDT6lKlhR9X+cLf1MCyuU3ExnrUBlY4=".data(using: .utf8)!

    override func setUp() {
        super.setUp()

        try! SecureRegistrationStorage.shared.clear()
    }

    func testRoundTrip() {
        let registrationService = SecureRegistrationStorage.shared

        XCTAssertNil(try! registrationService.get())

        try! registrationService.set(registration: Registration(id: id, secretKey: secretKey))

        let registration = try? registrationService.get()
        XCTAssertEqual(registration?.id, id)
        XCTAssertEqual(registration?.secretKey, secretKey)
    }

    func testOverwritesExistingRegistration() {
        // Add a registration
        let registrationService = SecureRegistrationStorage.shared
        try! registrationService.set(registration: Registration(id: UUID(), secretKey: secretKey))

        // Add another registration
        try! registrationService.set(registration: Registration(id: id, secretKey: secretKey))

        // We should have the new registration
        let registration = try? registrationService.get()
        XCTAssertEqual(registration?.id, id)
        XCTAssertEqual(registration?.secretKey, secretKey)
    }

    func testDoesNotAffectOtherGenericPasswords() {
        // Insert a generic password
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "my account",
            kSecValueData as String: "a password".data(using: .utf8)!,
        ]
        SecItemAdd(addQuery as CFDictionary, nil)

        // Set a registration
        let registrationService = SecureRegistrationStorage.shared
        try! registrationService.set(registration: Registration(id: UUID(), secretKey: secretKey))

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
