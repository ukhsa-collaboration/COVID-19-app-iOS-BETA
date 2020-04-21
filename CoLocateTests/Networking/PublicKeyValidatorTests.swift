//
//  PublicKeyValidatorTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class PublicKeyValidatorTests: XCTestCase {
    
    func testValidatorWithNoTrustedKeysDoesNotMatch() {
        let validator = PublicKeyValidator(trustedKeyHashes: [])
        XCTAssertFalse(validator.canAccept(.google))
    }
    
    func testValidatorWithUnrelatedTrustedKeyDoesNotMatch() {
        let validator = PublicKeyValidator(trustedKeyHashes: [CertificateSpecifier.appleLeaf.hash])
        XCTAssertFalse(validator.canAccept(.google))
    }
    
    func testValidatorDoesNotTrustedEmptyTrustObject() {
        let validator = PublicKeyValidator(trustedKeyHashes: [CertificateSpecifier.appleLeaf.hash])
        XCTAssertFalse(validator.canAccept(nil))
    }
    
    func testValidatorWithLeafTrustedKeyMatches() {
        let validator = PublicKeyValidator(trustedKeyHashes: [CertificateSpecifier.googleLeaf.hash])
        XCTAssert(validator.canAccept(.google))
    }
    
    func testValidatorWithIntermediateTrustedKeyMatches() {
        let validator = PublicKeyValidator(trustedKeyHashes: [CertificateSpecifier.googleIntermediate.hash])
        XCTAssert(validator.canAccept(.google))
    }
    
    func testValidatorWithRootTrustedKeyMatches() {
        let validator = PublicKeyValidator(trustedKeyHashes: [CertificateSpecifier.googleRoot.hash])
        XCTAssert(validator.canAccept(.google))
    }
    
}

private struct CertificateSpecifier {
    var name: String
    var hash: String
    
    // You can generate hashes from the command line:
    // ```
    // openssl x509 -pubkey -inform der -noout -in "$CERT_FILE" | grep -v PUBLIC | base64 -d | openssl dgst -sha256 -binary | base64
    // ```
    
    static let appleLeaf = CertificateSpecifier(name: "www.apple.com", hash: "t3XGIs7ZI5HZ1vLmt5/SQCoT5X0I27E73Pq0diuC3g0=")
    static let googleLeaf = CertificateSpecifier(name: "www.google.com", hash: "9U1/dqob7wLtVzss3MaRQ0d7P9szcHb6SfD4byW0f4A=")
    static let googleIntermediate = CertificateSpecifier(name: "GTS CA 1O1", hash: "YZPgTZ+woNCCCIW3LH2CxQeLzB/1m42QcCTBSdgayjs=")
    static let googleRoot = CertificateSpecifier(name: "GlobalSign", hash: "iie1VXtL7HzAMF+/PVPR9xzT80kQxdZeJ+zduCB3uj0=")

    var certificate: SecCertificate {
        let url = Bundle(for: PublicKeyValidatorTests.self).url(forResource: name, withExtension: "cer")!
        return SecCertificateCreateWithData(nil, try! Data(contentsOf: url) as CFData)!
    }
}

private extension SecTrust {
    
    static let google: SecTrust = {
        let certificates = [
            CertificateSpecifier.googleLeaf,
            CertificateSpecifier.googleIntermediate,
            CertificateSpecifier.googleRoot,
            ].map { $0.certificate }
        
        var trust: SecTrust?
        SecTrustCreateWithCertificates(certificates as CFTypeRef, SecPolicyCreateBasicX509(), &trust)
        return trust!
    }()
    
}
