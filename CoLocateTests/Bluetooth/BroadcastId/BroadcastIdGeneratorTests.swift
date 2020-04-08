//
//  BroadcastIdGeneratorTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
import Security

@testable import CoLocate

class BroadcastIdGeneratorTests: XCTestCase {

    let cannedId = UUID(uuidString: "E1D160C7-F6E8-48BC-8687-63C696D910CB")!

    let colocateEpoch = "2020-04-01"
    let dateFormatter = DateFormatter()

    var knownDate: Date!
    var laterDate: Date!

    var generator: BroadcastIdGenerator!

    override func setUp() {
        super.setUp()

        dateFormatter.dateFormat = "yyyy-MM-dd"
        knownDate = dateFormatter.date(from:colocateEpoch)!
        laterDate = knownDate.addingTimeInterval(86400)

        let serverPublicKey = knownGoodECPublicKey()

        generator = BroadcastIdGenerator(key: serverPublicKey, sonarId: cannedId)
    }

    func test_generates_ciphertext_that_are_the_correct_size() {
        let encryptedId = generator.broadcastId(for: knownDate, until: laterDate)

        // first byte is 0x04 -- indicates this is uncompressed
        let firstByte = encryptedId[0]
        XCTAssertEqual(0x04, firstByte)

        // the next 64 bytes are the public key we used to encrypt this
        // followed by 24 bytes for our ciphertext
        // and finally 16 bytes that is the gcm tag
        XCTAssertEqual(105, encryptedId.count)
    }

    func test_ciphertext_contains_expected_data() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("Cannot run this test in the simulator")
        #endif

        guard let (serverPublicKey, serverPrivateKey) = generateKeyPair() else {
            XCTFail("Expected to generate a keypair for this test but it failed")
            return
        }

        generator = BroadcastIdGenerator(key: serverPublicKey, sonarId: cannedId)
        let result = generator.broadcastId(for: knownDate, until: laterDate)

        let clearText = SecKeyCreateDecryptedData(serverPrivateKey,
                                                  .eciesEncryptionStandardX963SHA256AESGCM,
                                                  result as CFData,
                                                  nil) as Data?
        XCTAssertNotNil(clearText)

        let startDate = clearText!.subdata(in: 0..<4)
        let endDate   = clearText!.subdata(in: 4..<8)
        let uuidBytes = clearText!.subdata(in: 8..<24)

        XCTAssertEqual(1585692000, asInt(startDate))
        XCTAssertEqual(1585778400, asInt(endDate))
        XCTAssertEqual("E1D160C7-F6E8-48BC-8687-63C696D910CB", asUUIDString(uuidBytes))
    }

    func test_generates_the_same_result_for_the_same_inputs() {
        let first = generator.broadcastId(for: knownDate, until: laterDate)
        let second = generator.broadcastId(for: knownDate, until: laterDate)

        XCTAssertEqual(first, second)
    }

    func test_generates_a_different_id_for_different_days() {
        let todaysId = generator.broadcastId(for: knownDate)
        let tomorrowsId = generator.broadcastId(for: laterDate)

        XCTAssertNotEqual(todaysId, tomorrowsId)
    }

    //MARK: - Private
    private func knownGoodECPublicKey() -> SecKey {
        let base64EncodedKey = "BDSTjw7/yauS6iyMZ9p5yl6i0n3A7qxYI/3v+6RsHt8o+UrFCyULX3fKZuA6ve+lH1CAItezr+Tk2lKsMcCbHMI="

        let data = Data.init(base64Encoded: base64EncodedKey)!

        let keyDict : [NSObject:NSObject] = [
           kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
           kSecAttrKeyClass: kSecAttrKeyClassPublic,
           kSecAttrKeySizeInBits: NSNumber(value: 256),
           kSecReturnPersistentRef: true as NSObject
        ]

        return SecKeyCreateWithData(data as CFData, keyDict as CFDictionary, nil)!
    }

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

        let attributes: [String: Any] = [
          kSecAttrKeyType as String:            kSecAttrKeyTypeECSECPrimeRandom,
          kSecAttrKeySizeInBits as String:      256,
          kSecAttrTokenID as String:            kSecAttrTokenIDSecureEnclave,
          kSecPrivateKeyAttrs as String: [
            kSecAttrIsPermanent as String:      true,
            kSecAttrApplicationTag as String:   "this.was.a.good.test",
            kSecAttrAccessControl as String:    access!
          ]
        ]

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
