//
//  UpdatePushNotificationTests.swift
//  SonarTests
//
//  Created by NHSX on 21/5/2020
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class UpdatePushNotificationTokenRequestTests: XCTestCase {
    
    var token: String!
    var registration: Registration!
    var sut: UpdatePushNotificationTokenRequest!

    override func setUpWithError() throws {
        token = UUID().uuidString
        registration = Registration.fake
        sut = UpdatePushNotificationTokenRequest(registration: registration, token: token)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testRequestBody() throws {
        
        struct Body: Codable, Equatable {
            var sonarId: String
            var pushNotificationToken: String
        }
        
        let decodedBody = try JSONDecoder().decode(Body.self, from: XCTUnwrap(sut.method.body))
        XCTAssertEqual(decodedBody.pushNotificationToken, token)
        XCTAssertEqual(decodedBody.sonarId, registration.sonarId.uuidString)
        XCTAssertEqual(sut.method.name, "PUT")
    }

}
