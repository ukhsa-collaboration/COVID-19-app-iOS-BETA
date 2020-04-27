//
//  BroadcastIdEncypterTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
import Security

@testable import CoLocate

class BroadcastIdEncypterTests: XCTestCase {

    let cannedId = UUID(uuidString: "E1D160C7-F6E8-48BC-8687-63C696D910CB")!

    let colocateEpoch = "2020-04-01T00:00:00Z"
    let dateFormatter = DateFormatter()

    var knownDate: Date!
    var slightlyLaterDate: Date!
    var muchLaterDate: Date!

    var encrypter: BroadcastIdEncrypter!

    override func setUp() {
        super.setUp()

        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        knownDate = dateFormatter.date(from:colocateEpoch)!
        slightlyLaterDate = knownDate.addingTimeInterval(1)
        muchLaterDate = knownDate.addingTimeInterval(86400)

        let serverPublicKey = knownGoodECPublicKey()

        encrypter = BroadcastIdEncrypter(key: serverPublicKey, sonarId: cannedId)
    }

    func test_generates_ciphertext_that_are_the_correct_size() {
        let encryptedId = encrypter.broadcastId(for: knownDate, until: muchLaterDate)

        // the first 64 bytes are the epheraml public key used for encryption
        // followed by 26 bytes for our ciphertext
        // and finally 16 bytes that is the gcm tag
        XCTAssertEqual(106, encryptedId.count)
    }

    func test_ciphertext_contains_expected_data() throws {
        guard let (serverPublicKey, serverPrivateKey) = generateKeyPair() else {
            XCTFail("Expected to generate a keypair for this test but it failed")
            return
        }

        encrypter = BroadcastIdEncrypter(key: serverPublicKey, sonarId: cannedId)
        let result = encrypter.broadcastId(for: knownDate, until: muchLaterDate)

        // first byte would be 0x04 -- indicates uncompressed point format
        // BUT  we do not transmit this, in order to save space
        var specialByte = 0x04
        let firstByte = Data(bytes: &specialByte, count: 1)
        let fullCipherText = NSMutableData()
        fullCipherText.append(firstByte)
        fullCipherText.append(result)

        let clearText = SecKeyCreateDecryptedData(serverPrivateKey,
                                                  .eciesEncryptionStandardVariableIVX963SHA256AESGCM,
                                                  fullCipherText as CFData,
                                                  nil) as Data?
        XCTAssertNotNil(clearText)

        let startDate = clearText!.subdata(in: 0..<4)
        let endDate   = clearText!.subdata(in: 4..<8)
        let uuidBytes = clearText!.subdata(in: 8..<24)
        let country   = clearText!.subdata(in: 24..<26)

        XCTAssertEqual(1585699200, asInt(startDate))
        XCTAssertEqual(1585785600, asInt(endDate))
        XCTAssertEqual("E1D160C7-F6E8-48BC-8687-63C696D910CB", asUUIDString(uuidBytes))
        XCTAssertEqual(826, asInt(country)) // iso 3166 country code for UK
    }

    func test_generates_the_same_result_for_the_same_inputs() {
        let first = encrypter.broadcastId(for: knownDate, until: muchLaterDate)
        let second = encrypter.broadcastId(for: knownDate, until: muchLaterDate)

        XCTAssertEqual(first, second)
    }

    func test_generates_the_same_result_for_the_same_day() {
        let first = encrypter.broadcastId(for: knownDate, until: muchLaterDate)
        let second = encrypter.broadcastId(for: slightlyLaterDate, until: muchLaterDate)

        XCTAssertEqual(first, second)
    }

    func test_generates_a_different_id_for_different_days() throws {
        let todaysId = encrypter.broadcastId(for: knownDate)
        let tomorrowsId = encrypter.broadcastId(for: muchLaterDate)

        XCTAssertNotEqual(todaysId, tomorrowsId)
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
