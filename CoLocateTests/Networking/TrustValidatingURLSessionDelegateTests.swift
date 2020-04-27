//
//  TrustValidatingURLSessionDelegateTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class TrustValidatingURLSessionDelegateTests: XCTestCase {
    
    func testAcceptingTrust() {
        let delegate = TrustValidatingURLSessionDelegate(validator: TrustValidatingDouble(shouldAccept: true))
        var disposition: URLSession.AuthChallengeDisposition?
        var credential: URLCredential?
        delegate.urlSession(.shared, didReceive: .example) {
            disposition = $0
            credential = $1
        }
        
        XCTAssertNil(credential)
        XCTAssertEqual(disposition, .performDefaultHandling)
    }
    
    func testRejectingTrust() {
        let delegate = TrustValidatingURLSessionDelegate(validator: TrustValidatingDouble(shouldAccept: false))
        var disposition: URLSession.AuthChallengeDisposition?
        var credential: URLCredential?
        delegate.urlSession(.shared, didReceive: .example) {
            disposition = $0
            credential = $1
        }
        
        XCTAssertNil(credential)
        XCTAssertEqual(disposition, .cancelAuthenticationChallenge)
    }
    
}
