//
//  SecureBroadcastRotationKeyStorageTests.swift
//  SonarTests
//
//  Created by NHSX on 07/04/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
import Security

@testable import Sonar

class SecureBroadcastRotationKeyStorageTests: XCTestCase {

    let storage = SecureBroadcastRotationKeyStorage()

    override func setUp() {
        super.setUp()

        try! storage.clear()
    }

    func test_saves_the_key_and_reads_it_back() throws {
        try storage.save(publicKey: SecKey.sampleEllipticCurveKey)

        let otherWrapper = SecureBroadcastRotationKeyStorage()
        let readKey = otherWrapper.read()

        XCTAssertNotNil(readKey)
    }

    func test_returns_nil_if_no_key_was_saved() {
        let readKey = storage.read()

        XCTAssertNil(readKey)
    }
    
    func test_saves_broadcastId() {
        let middayToday = Date().midday
        
        storage.save(broadcastId: "looks like a broadcastId".data(using: .utf8)!, date: middayToday)

        let otherWrapper = SecureBroadcastRotationKeyStorage()
        let (broadcastId, date) = otherWrapper.readBroadcastId()!

        XCTAssertEqual(broadcastId, "looks like a broadcastId".data(using: .utf8)!)
        XCTAssertEqual(date, middayToday)
    }

}
