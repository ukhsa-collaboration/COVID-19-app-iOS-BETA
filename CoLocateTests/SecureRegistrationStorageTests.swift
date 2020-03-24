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
        let registrationService = SecureRegistrationStorage.shared
        try! registrationService.set(registration: Registration(id: UUID(), secretKey: "a secret key"))

        try! registrationService.set(registration: Registration(id: id, secretKey: secretKey))

        let registration = try? registrationService.get()
        XCTAssertEqual(registration?.id, id)
        XCTAssertEqual(registration?.secretKey, secretKey)
    }

}
