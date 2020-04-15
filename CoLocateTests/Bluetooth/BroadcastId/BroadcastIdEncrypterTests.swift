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
    var laterDate: Date!

    var encrypter: BroadcastIdEncrypter!

    override func setUp() {
        super.setUp()

        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        knownDate = dateFormatter.date(from:colocateEpoch)!
        laterDate = knownDate.addingTimeInterval(86400)

        let serverPublicKey = knownGoodECPublicKey()

        encrypter = BroadcastIdEncrypter(key: serverPublicKey, sonarId: cannedId)
    }

    override func tearDown() {
        Persistence.shared.enableNewKeyRotation = false
    }

    func test_returns_uuid_as_bytes_by_default() throws {
        Persistence.shared.enableNewKeyRotation = false

        let data = encrypter.broadcastId(for: knownDate)
        XCTAssertEqual("E1D160C7-F6E8-48BC-8687-63C696D910CB", asUUIDString(data))
    }

    func test_generates_ciphertext_that_are_the_correct_size() {
        Persistence.shared.enableNewKeyRotation = true

        let encryptedId = encrypter.broadcastId(for: knownDate, until: laterDate)

        // the first 64 bytes are the epheraml public key used for encryption
        // followed by 24 bytes for our ciphertext
        // and finally 16 bytes that is the gcm tag
        XCTAssertEqual(104, encryptedId.count)
    }

    func test_generates_uuids_of_correct_size() {
        Persistence.shared.enableNewKeyRotation = false
        let uuidAsData = encrypter.broadcastId(for: knownDate, until: laterDate)

        XCTAssertEqual(16, uuidAsData.count)
    }

    func test_ciphertext_contains_expected_data() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("Cannot run this test in the simulator")
        #endif

        Persistence.shared.enableNewKeyRotation = true

        guard let (serverPublicKey, serverPrivateKey) = generateKeyPair() else {
            XCTFail("Expected to generate a keypair for this test but it failed")
            return
        }

        encrypter = BroadcastIdEncrypter(key: serverPublicKey, sonarId: cannedId)
        let result = encrypter.broadcastId(for: knownDate, until: laterDate)

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

        XCTAssertEqual(1585699200, asInt(startDate))
        XCTAssertEqual(1585785600, asInt(endDate))
        XCTAssertEqual("E1D160C7-F6E8-48BC-8687-63C696D910CB", asUUIDString(uuidBytes))
    }

    func test_generates_the_same_result_for_the_same_inputs() {
        Persistence.shared.enableNewKeyRotation = true

        let first = encrypter.broadcastId(for: knownDate, until: laterDate)
        let second = encrypter.broadcastId(for: knownDate, until: laterDate)

        XCTAssertEqual(first, second)
    }

    func test_generates_a_different_id_for_different_days() throws {
        Persistence.shared.enableNewKeyRotation = true

        let todaysId = encrypter.broadcastId(for: knownDate)
        let tomorrowsId = encrypter.broadcastId(for: laterDate)

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
