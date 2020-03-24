//
//  RegistrationRequestTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest

@testable import CoLocate

class RegistrationRequestTests: XCTestCase {
    func testParse() {
        let request = RequestFactory.registrationRequest()
        let encodedResponse = try! JSONEncoder().encode(
            RegistrationResponse(
                id: UUID(uuidString: "1c8d305e-db93-4ba0-81f4-94c33fd35c7c")!,
                secretKey: "Ik6M9N2CqLv3BDT6lKlhR9X+cLf1MCyuU3ExnrUBlY4="
            )
        )
        
        let actualResponse = try? request.parse(encodedResponse)
        
        XCTAssertEqual(actualResponse?.id, UUID(uuidString: "1c8d305e-db93-4ba0-81f4-94c33fd35c7c")!)
        XCTAssertEqual(actualResponse?.secretKey, "Ik6M9N2CqLv3BDT6lKlhR9X+cLf1MCyuU3ExnrUBlY4=")
    }
}
