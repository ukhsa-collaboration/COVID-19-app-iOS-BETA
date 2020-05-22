//
//  LinkingIdRequest.swift
//  SonarTests
//
//  Created by NHSX on 22/5/2020
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class LinkingIdRequestTests: XCTestCase {
    let registration = Registration.fake
    var sut: LinkingIdRequest!

    override func setUpWithError() throws {
        sut = LinkingIdRequest(registration: registration)
    }

    func testEndPointURL() throws {
        XCTAssertEqual(sut.url.path, "/api/app-instances/linking-id")
    }
    
    func testRequestBody() throws {
        struct Body: Codable, Equatable {
            var sonarId: String
        }
        
        let decodedBody = try JSONDecoder().decode(Body.self, from: XCTUnwrap(sut.method.body))
        XCTAssertEqual(decodedBody.sonarId, registration.sonarId.uuidString)
        XCTAssertEqual(sut.method.name, "PUT")
    }
}
