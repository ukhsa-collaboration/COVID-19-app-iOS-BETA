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
    let secretKey = "Ik6M9N2CqLv3BDT6lKlhR9X+cLf1MCyuU3ExnrUBlY4="

    override func setUp() {
        super.setUp()

        // Reset the keychain to a known empty state.
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
        ]
        let status = SecItemDelete(query as CFDictionary)

        // If the test succeeds, the delete will be successful. If the test
        // fails, then we expect the item to not be found.
        XCTAssert(status == errSecSuccess || status == errSecItemNotFound)
    }

    func testRoundTrip() {
        let registrationService = SecureRegistrationStorage()

        XCTAssertNil(try! registrationService.get())

        try! registrationService.set(registration: Registration(id: id, secretKey: secretKey))

        let registration = try? registrationService.get()
        XCTAssertEqual(registration?.id, id)
        XCTAssertEqual(registration?.secretKey, secretKey)
    }

    func testOverwritesExistingRegistration() {
        let registrationService = SecureRegistrationStorage()
        try! registrationService.set(registration: Registration(id: UUID(), secretKey: "a secret key"))

        try! registrationService.set(registration: Registration(id: id, secretKey: secretKey))

        let registration = try? registrationService.get()
        XCTAssertEqual(registration?.id, id)
        XCTAssertEqual(registration?.secretKey, secretKey)
    }

}
