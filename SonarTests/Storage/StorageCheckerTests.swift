//
//  StorageCheckerTests.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class StorageCheckerTests: XCTestCase {
    
    private var checker = StorageChecker(service: service)
    
    override func setUp() {
        super.setUp()
        clear()
    }
    
    func testStartsNotInitialized() {
        XCTAssertEqual(checker.state, .notInitialized)
    }
    
    func testStartsAsSynced() throws {
        let token = UUID().data
        writeToKeychain(with: token)
        writeToUserDefaults(with: token)
        
        XCTAssertEqual(checker.state, .inSync)
    }
    
    func testStartsAsNotSyncedWhenOnlyKeychainHasValue() throws {
        let token = UUID().data
        writeToKeychain(with: token)
        
        XCTAssertEqual(checker.state, .keyChainAndUserDefaultsNotInSync)
    }
    
    func testStartsAsNotSyncedWhenOnlyUserDefaultsHasValue() throws {
        let token = UUID().data
        writeToUserDefaults(with: token)
        
        XCTAssertEqual(checker.state, .keyChainAndUserDefaultsNotInSync)
    }
    
    func testStartsAsNotSyncedWhenValuesDiffer() throws {
        writeToUserDefaults(with: UUID().data)
        writeToKeychain(with: UUID().data)

        XCTAssertEqual(checker.state, .keyChainAndUserDefaultsNotInSync)
    }
    
    func testMarkingAsSynced() throws {
        checker.markAsSynced()
        XCTAssertEqual(checker.state, .inSync)
        
        let valueInKeychain = try XCTUnwrap(readFromKeychain())
        let valueInDefaults = try XCTUnwrap(readFromUserDefaults())
        XCTAssertEqual(valueInDefaults, valueInKeychain)
    }
        
    func testMarkingAsSyncedOverridesExistingKeysCorrectly() throws {
        writeToUserDefaults(with: UUID().data)
        writeToKeychain(with: UUID().data)
        
        checker.markAsSynced()
        XCTAssertEqual(checker.state, .inSync)
        
        let valueInKeychain = try XCTUnwrap(readFromKeychain())
        let valueInDefaults = try XCTUnwrap(readFromUserDefaults())
        XCTAssertEqual(valueInDefaults, valueInKeychain)
    }
        
}

private extension StorageCheckerTests {
    
    func clear() {
        clearValueInUserDefaults()
        clearValueInKeychain()
    }
    
    func writeToUserDefaults(with token: Data) {
        UserDefaults.standard.set(token, forKey: service)
    }
    
    func readFromUserDefaults() -> UUID? {
        guard let data = UserDefaults.standard.object(forKey: service) as? Data else { return nil }
        return UUID(data: data)
    }
        
    func clearValueInUserDefaults() {
        UserDefaults.standard.removeObject(forKey: service)
    }

    // TODO: Refactor below.
    // We’re duplicating keychain logic here.
    // Ideally, need to extract this when we have an interface for keychain storage.
    //
    // Despite the duplication, the test is completely valid as we’re doing a round-trip through keychain.
    
    func writeToKeychain(with token: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecValueData as String: token,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func readFromKeychain() -> UUID? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true,
        ]
        
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        
        let data = result as! CFData
        return UUID(data: data as Data)
    }
    
    func clearValueInKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
        ]
        SecItemDelete(query as CFDictionary)
    }
    
}

private let service = UUID().uuidString
