//
//  PlistPersisterTests.swift
//  SonarTests
//
//  Created by NHSX on 13.04.20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class PlistPersisterTests: XCTestCase {

    private var persister: PlistPersister<String, Sample>!
    
    private var item1: Sample!
    private var item2: Sample!
    private var item3: Sample!
    
    override func setUp() {
        persister = PlistPersister<String, Sample>(fileName: "samples")
        persister.reset()
        
        item1 = Sample(name: "Hewie", number: 1)
        item2 = Sample(name: "Dewie", number: 2)
        item3 = Sample(name: "Louie", number: 3)
    }

    func testRecordsItems() {
        XCTAssertEqual(persister.items, [:])

        persister.update(item: item1, key: "item1")
        persister.update(item: item2, key: "item2")
        persister.update(item: item3, key: "item3")

        XCTAssertEqual(persister.items.count, 3)
        XCTAssertEqual(persister.items["item1"], item1)
        XCTAssertEqual(persister.items["item2"], item2)
        XCTAssertEqual(persister.items["item3"], item3)
    }
    
    func testRemoveKey() {
        XCTAssertEqual(persister.items, [:])

        persister.update(item: item1, key: "item1")
        persister.update(item: item2, key: "item2")
        persister.update(item: item3, key: "item3")

        persister.remove(key: "item2")
        
        XCTAssertEqual(persister.items.count, 2)
    }

    func testPersistsItems() throws {
        XCTAssertFalse(FileManager.default.fileExists(atPath: persister.fileURL.path))

        persister.update(item: item1, key: "item1")
        persister.update(item: item2, key: "item2")
        persister.update(item: item3, key: "item3")

        XCTAssertTrue(FileManager.default.fileExists(atPath: persister.fileURL.path))
        let otherPersister = PlistPersister<String, Sample>(fileName: "samples")
        XCTAssertEqual(otherPersister.items, ["item1": item1, "item2": item2, "item3": item3])
    }
}

private struct Sample: Codable, Equatable {
    let name: String
    let number: Int
}
