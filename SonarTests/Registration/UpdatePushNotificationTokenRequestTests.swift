//
//  UpdatePushNotificationTests.swift
//  SonarTests
//
//  Created by NHSX on 21/5/2020
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
import CommonCrypto
@testable import Sonar

class UpdatePushNotificationTokenRequestTests: XCTestCase {
    
    let timestampHeader = "Sonar-Request-Timestamp"
    let signatureHeader = "Sonar-Message-Signature"
    
    var token: String!
    var registration: Registration!
    var sut: UpdatePushNotificationTokenRequest!

    override func setUpWithError() throws {
        token = UUID().uuidString
        registration = Registration.fake
        sut = UpdatePushNotificationTokenRequest(registration: registration, token: token)
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
    
    func testURLPath() {
        XCTAssertEqual(sut.urlable, .path("/api/registration/push-notification-token"))
    }
    
    func testHeaders() throws {
        let key = registration.secretKey
        
        func secureRequestImplementation() throws -> (timestamp: String, authCode: Data) {
            let timestamp = Date()
            let timestampString = ISO8601DateFormatter().string(from: timestamp)
            var hmacContext = CCHmacContext()

            key.data.withUnsafeBytes { keyPtr -> Void in
                CCHmacInit(&hmacContext, CCHmacAlgorithm(kCCHmacAlgSHA256), keyPtr.baseAddress, key.data.count)
            }
            
            let tsData = timestampString.data(using: .utf8)!
            tsData.withUnsafeBytes { (tsPtr: UnsafeRawBufferPointer) -> Void in
                CCHmacUpdate(&hmacContext, tsPtr.baseAddress, tsData.count)
            }
            
            let data = try! XCTUnwrap(sut.method.body)
            data.withUnsafeBytes { (dataPtr: UnsafeRawBufferPointer) -> Void in
                CCHmacUpdate(&hmacContext, dataPtr.baseAddress, data.count)
            }
            
            var authenticationCode = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
            authenticationCode.withUnsafeMutableBytes { (digestPtr: UnsafeMutableRawBufferPointer) -> Void in
                CCHmacFinal(&hmacContext, digestPtr.baseAddress)
            }
            
            return (timestampString, authenticationCode)
        }

        let duplicatedTestImplementation = try! secureRequestImplementation()
        XCTAssertEqual(sut.headers["Content-Type"], "application/json")
        XCTAssertEqual(sut.headers[timestampHeader], duplicatedTestImplementation.timestamp)
        XCTAssertEqual(sut.headers[signatureHeader], duplicatedTestImplementation.authCode.base64EncodedString())
    }

}
