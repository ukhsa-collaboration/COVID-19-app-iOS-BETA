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
        let delegate = TrustValidatingURLSessionDelegate(validator: MockTrustValidator(accept: true))
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
        let delegate = TrustValidatingURLSessionDelegate(validator: MockTrustValidator(accept: false))
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

private extension URLAuthenticationChallenge {
    static let example = URLAuthenticationChallenge(
        protectionSpace: .example,
        proposedCredential: nil,
        previousFailureCount: 0,
        failureResponse: nil,
        error: nil,
        sender: MockURLAuthenticationChallengeSender()
    )
}

private extension URLProtectionSpace {
    static let example = URLProtectionSpace(
        host: "example.com",
        port: 443,
        protocol: NSURLProtectionSpaceHTTPS,
        realm: nil,
        authenticationMethod: NSURLAuthenticationMethodServerTrust
    )
}

private struct MockTrustValidator: TrustValidating {
    
    var accept: Bool
    
    func canAccept(_ trust: SecTrust?) -> Bool {
        return accept
    }
}

private class MockURLAuthenticationChallengeSender: NSObject, URLAuthenticationChallengeSender {
    
    func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {
        
    }

    func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {
        
    }
    
    func cancel(_ challenge: URLAuthenticationChallenge) {
        
    }
    
    func performDefaultHandling(for challenge: URLAuthenticationChallenge) {
        
    }
    
    func rejectProtectionSpaceAndContinue(with challenge: URLAuthenticationChallenge) {
        
    }

}
