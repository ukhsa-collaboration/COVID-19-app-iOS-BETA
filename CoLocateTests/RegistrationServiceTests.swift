//
//  RegistrationTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Security
import XCTest
@testable import CoLocate

class RegistrationServiceTests: XCTestCase {
    let id = UUID(uuidString: "1c8d305e-db93-4ba0-81f4-94c33fd35c7c")!
    let secretKey = "Ik6M9N2CqLv3BDT6lKlhR9X+cLf1MCyuU3ExnrUBlY4="

    override func setUp() {
        // Reset the keychain to a known empty state.
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: id.uuidString,
            kSecValueData as String: secretKey.data(using: .utf8)!,
        ]
        let status = SecItemDelete(query as CFDictionary)

        // If the test succeeds, the delete will be successful. If the test
        // fails, then we expect the item to not be found.
        XCTAssert(status == errSecSuccess || status == errSecItemNotFound)

        super.tearDown()
    }

    func testRoundTrip() {
        let registrationService = RegistrationService()

        XCTAssertNil(try! registrationService.get())

        try! registrationService.set(registration: Registration(id: id, secretKey: secretKey))

        let registration = try? registrationService.get()
        XCTAssertEqual(registration?.id, id)
        XCTAssertEqual(registration?.secretKey, secretKey)
    }
}
