//
//  BroadcastIdEncypterTests.swift
//  SonarTests
//
//  Created by NHSX on 08/04/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
import Security
import CommonCrypto

@testable import Sonar

class BroadcastIdEncypterTests: XCTestCase {

    let sonarId = UUID(uuidString: "E1D160C7-F6E8-48BC-8687-63C696D910CB")!
    
    let sonarEpoch = "2020-04-01T00:00:00Z"
    let dateFormatter = DateFormatter()
    let ukISO3166CountryCode: UInt16 = 826
    let txPower: Int8 = 0
    let serverPublicKey = SecKey.sampleEllipticCurveKey

    var knownDate: Date!
    var slightlyLaterDate: Date!
    var txDate: Date!
    var muchLaterDate: Date!

    var encrypter: ConcreteBroadcastIdEncrypter!

    override func setUp() {
        super.setUp()

        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        knownDate = dateFormatter.date(from:sonarEpoch)!
        slightlyLaterDate = knownDate.addingTimeInterval(1)
        txDate = knownDate.addingTimeInterval(5 * 60)
        muchLaterDate = knownDate.addingTimeInterval(86400)

        encrypter = ConcreteBroadcastIdEncrypter()
    }
    
    func test_generates_ciphertext_that_are_the_correct_size() {
        let encryptedId = encrypter.broadcastId(secKey: serverPublicKey, sonarId: sonarId, from: knownDate, until: muchLaterDate)

        // the first 64 bytes are the epheraml public key used for encryption
        // followed by 26 bytes for our ciphertext
        // and finally 16 bytes that is the gcm tag
        XCTAssertEqual(106, encryptedId.count)
    }

    func test_ciphertext_contains_expected_cryptogram() throws {
        guard let (serverPublicKey, serverPrivateKey) = generateKeyPair() else {
            XCTFail("Expected to generate a keypair for this test but it failed")
            return
        }

        encrypter = ConcreteBroadcastIdEncrypter()
        let result = encrypter.broadcastId(secKey: serverPublicKey, sonarId: sonarId, from: knownDate, until: muchLaterDate)

        // first byte would be 0x04 -- indicates uncompressed point format
        // BUT  we do not transmit this, in order to save space
        var specialByte = 0x04
        let firstByte = Data(bytes: &specialByte, count: 1)
        var cryptogram = Data()
        cryptogram.append(firstByte)
        cryptogram.append(result)

        let clearText = SecKeyCreateDecryptedData(serverPrivateKey,
                                                  .eciesEncryptionStandardVariableIVX963SHA256AESGCM,
                                                  cryptogram as CFData,
                                                  nil) as Data?
        XCTAssertNotNil(clearText)

        let startDate   = clearText!.subdata(in: 0..<4)
        let endDate     = clearText!.subdata(in: 4..<8)
        let uuidBytes   = clearText!.subdata(in: 8..<24)
        let countryCode = clearText!.subdata(in: 24..<26)

        XCTAssertEqual(UInt32(1585699200).bigEndian, startDate.to(type: UInt32.self))
        XCTAssertEqual(UInt32(1585785600).bigEndian, endDate.to(type: UInt32.self))
        XCTAssertEqual(sonarId, UUID(data: uuidBytes))
        XCTAssertEqual(UInt16(826).bigEndian, countryCode.to(type: UInt16.self)) // iso 3166 country code for UK
    }

    //MARK: - Private

    private func generateKeyPair() -> (SecKey, SecKey)? {
        var error: Unmanaged<CFError>?

        let access = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleAfterFirstUnlock,
            .privateKeyUsage,
            &error
        )
        guard error == nil else {
            return nil
        }

        var attributes: [String: Any] = [
          kSecAttrKeyType as String:            kSecAttrKeyTypeECSECPrimeRandom,
          kSecAttrKeySizeInBits as String:      256,
          kSecPrivateKeyAttrs as String: [
            kSecAttrIsPermanent as String:      true,
            kSecAttrApplicationTag as String:   "this.was.a.good.test",
            kSecAttrAccessControl as String:    access!
          ]
        ]

        #if targetEnvironment(simulator)
        #else
            attributes[kSecAttrTokenID as String] = kSecAttrTokenIDSecureEnclave
        #endif

        let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error)
        guard error == nil else {
            return nil
        }

        let publicKey = SecKeyCopyPublicKey(privateKey!)

        return (publicKey!, privateKey!)
    }

    private func asInt(_ data: Data) -> Int32 {
        return data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> Int32 in
            return pointer.baseAddress!.assumingMemoryBound(to: Int32.self).pointee
        }
    }

    private func asUUIDString(_ data: Data) -> String {
        let uuid = data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> UUID in
            return pointer.baseAddress!.assumingMemoryBound(to: UUID.self).pointee
        }

        return uuid.uuidString
    }

}
