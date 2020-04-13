//
//  PlistPersisterTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class PlistPersisterTests: XCTestCase {

    var persister: PlistPersister<Sample>!
    
    var item1: Sample!
    var item2: Sample!
    var item3: Sample!
    
    override func setUp() {
        persister = PlistPersister<Sample>(fileName: "samples")
        persister.reset()
        
        item1 = Sample(name: "Hewie", number: 1)
        item2 = Sample(name: "Dewie", number: 2)
        item3 = Sample(name: "Louie", number: 3)
    }

    func testRecordsItems() {
        XCTAssertEqual(persister.items, [])

        persister.items.append(item1)
        persister.items.append(item2)
        persister.items.append(item3)

        XCTAssertEqual(persister.items.count, 3)
        XCTAssertEqual(persister.items[0], item1)
        XCTAssertEqual(persister.items[1], item2)
        XCTAssertEqual(persister.items[2], item3)
    }

    func testPersistsItems() throws {
        XCTAssertFalse(FileManager.default.fileExists(atPath: persister.fileURL.path))

        persister.items.append(item1)
        persister.items.append(item2)
        persister.items.append(item3)

        let attrs = try FileManager.default.attributesOfItem(atPath: persister.fileURL.path)
        XCTAssertNotEqual(attrs[.size] as! NSNumber, 0)
    }

    func testLoadsItemsFromDiskOnInit() {
        persister.items.append(item1)
        persister.items.append(item2)
        persister.items.append(item3)

        persister = nil

        persister = PlistPersister<Sample>(fileName: "samples")
        XCTAssertEqual(persister.items.count, 3)
    }

}

struct Sample: Codable, Equatable {
    let name: String
    let number: Int
}
