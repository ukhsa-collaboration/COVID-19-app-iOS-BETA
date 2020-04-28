//
//  URLSessionTests.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class URLSessionTests: XCTestCase {

    func test_has_correct_security_configuration() throws {
        let configuration = URLSession(trustValidator: TrustValidatingDouble()).configuration
        
        if #available(iOS 13.0, *) {
            XCTAssertEqual(configuration.tlsMinimumSupportedProtocolVersion, .TLSv12)
        }
        XCTAssertEqual(configuration.tlsMinimumSupportedProtocol, .tlsProtocol12)
        XCTAssertEqual(configuration.httpCookieAcceptPolicy, .never)
        XCTAssertFalse(configuration.httpShouldSetCookies)
        XCTAssertNil(configuration.httpCookieStorage)
        XCTAssertNil(configuration.urlCache)
    }
    
    func test_trust_validtor_is_used_to_configure_delegate() throws {
        let session = URLSession(trustValidator: TrustValidatingDouble(shouldAccept: false))
        
        var disposition: URLSession.AuthChallengeDisposition?
        var credential: URLCredential?
        session.delegate?.urlSession?(session, didReceive: .example) {
            disposition = $0
            credential = $1
        }
        
        XCTAssertNil(credential)
        XCTAssertEqual(disposition, .cancelAuthenticationChallenge)
    }
}
