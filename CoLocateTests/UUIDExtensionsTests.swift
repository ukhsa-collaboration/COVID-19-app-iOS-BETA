//
//  UUIDExtensionsTests.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate
import CoreBluetooth

class UUIDExtensionsTests: XCTestCase {

    let uuidString = "9A48A849-A169-4D5C-AFD5-783E16085680"
    let base64String = "mkioSaFpTVyv1Xg+FghWgA=="
                        
    var data: Data!
    var uuid: UUID!
    
    override func setUp() {
        data = Data(base64Encoded: base64String)!
        uuid = UUID(uuidString: uuidString)!
        
        print("uuid as base64 = \(CBUUID(string: uuidString).data.base64EncodedString())")
    }

    func testDataFromUUID() throws {
        XCTAssertEqual(uuid.data, data)
    }
    
    func testUUIDFromData() {
        XCTAssertEqual(UUID(data: data), uuid)
    }

    func testDataLength() {
        let data = Data(base64Encoded: "mkioSaFpTVyv1Xg+FghWgAgA")!
        
        XCTAssertNil(UUID(data: data))
    }

}
