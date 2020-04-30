//
//  PublicKeyValidator.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CommonCrypto

protocol TrustValidating {
    // It’s unfortunate that this API accepts an optional, but we have to do this due to testing limitations:
    // There’s no sane way to mock `URLProtectionSpace.serverTrust` property. To be able to have reasonable tests,
    // we need to decouple where we receive it (in the `URLSessionDelegate`) from where we unwrap it.
    //
    // There are other options, like implementing a `URLAuthenticationChallenge`-like protocol that returns a
    // `URLProtectionSpace`-like protocol, it’s not worth it (we wouldn’t be able to test the correct delegate method
    // with that anyway).
    func canAccept(_ trust: SecTrust?) -> Bool
}

#warning("This type should be removed after public key pinning is rolled out")
struct DefaultTrustValidating: TrustValidating {
    func canAccept(_ trust: SecTrust?) -> Bool {
        true
    }
}

class PublicKeyValidator: TrustValidating {
    
    private let trustedKeyHashes: Set<String>
    
    init(trustedKeyHashes: Set<String>) {
        self.trustedKeyHashes = trustedKeyHashes
    }
    
    func canAccept(_ trust: SecTrust?) -> Bool {
        guard let trust = trust else { return false }
        return trust.certificates.contains { certificate in
            guard let hash = certificate.publicKey?.hash else { return false }
            return trustedKeyHashes.contains(hash)
        }
    }
    
}

private extension SecTrust {
    
    var certificates: AnySequence<SecCertificate> {
        let certificatesCount = SecTrustGetCertificateCount(self)
        return AnySequence(sequence(state: 0) { index -> SecCertificate? in
            guard index < certificatesCount else { return nil }
            defer { index += 1 }
            return SecTrustGetCertificateAtIndex(self, index)
        })
    }
    
}

private extension SecCertificate {
    
    var publicKey: SecKey? {
        SecCertificateCopyPublicKey(self)
    }
    
}

extension SecKey {
    
    var hash: String? {
        // The hashed data is the DER representation of the key. This includes:
        // * the signature algorithm https://tools.ietf.org/html/rfc5280#section-4.1.1.2
        // * public key data https://tools.ietf.org/html/rfc2313#section-7.1
        
        // The latter is what we get from `externalRepresentation`. The former, as the name suggests, depends on the
        // algorithm.
        // We could try to encode this data “properly”, but is probably overkill since we’d have to write an ASN1
        // encoder ourselves. Instead, we hardcoded the common preamble for common algorithms. This is usually safe,
        // and a common approach on iOS apps (see, for example https://github.com/datatheorem/TrustKit/blob/8fab774d80879b49203d4c9ce88c322de1114f10/TrustKit/Pinning/TSKSPKIHashCache.m#L19)
        // Since our keys are part of the app bundle, we can verify the correct algorithm is supported.
        guard let derPreamble = derPreamble, let externalRepresentation = externalRepresentation else { return nil }
        let derData = derPreamble + externalRepresentation
        return derData.sha256Hash.base64EncodedString()
    }
    
    var externalRepresentation: Data? {
        SecKeyCopyExternalRepresentation(self, nil) as Data?
    }
    
    private var derPreamble: Data? {
        guard
            let attributes = SecKeyCopyAttributes(self) as? [String: Any],
            let algorithm = attributes[kSecAttrKeyType as String] as? String,
            let size = attributes[kSecAttrKeySizeInBits as String] as? Int
            else { return nil }
        
        if algorithm == kSecAttrKeyTypeRSA as String {
            return .rsaEncryption_Header
        } else if algorithm == kSecAttrKeyTypeECSECPrimeRandom as String && (size == 256) {
            return .ecPublicKey_prime256v1_Header
        } else {
            return nil
        }
    }
    
}

private extension Data {
    
    // https://tools.ietf.org/html/rfc2313#section-11
    static let rsaEncryption_Header = Data([
        0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05,
        0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
    ])
    
    // https://tools.ietf.org/html/rfc3279#section-2.3.5
    static let ecPublicKey_prime256v1_Header = Data([
        0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02, 0x01, 0x06, 0x08, 0x2a, 0x86, 0x48,
        0xce, 0x3d, 0x03, 0x01, 0x07, 0x03, 0x42, 0x00
    ])
    
    var sha256Hash: Data {
        withUnsafeBytes { bytes in
            var hash = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
            hash.withUnsafeMutableBytes { (hashBytes: UnsafeMutableRawBufferPointer) in
                _ = CC_SHA256(bytes.baseAddress, CC_LONG(count), hashBytes.bindMemory(to: UInt8.self).baseAddress)
            }
            return hash
        }
    }
    
}
