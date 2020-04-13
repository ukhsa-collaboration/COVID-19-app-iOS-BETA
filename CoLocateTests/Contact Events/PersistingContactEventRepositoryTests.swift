//
//  ContactEventCollectorTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class PersistingContactEventRepositoryTests: XCTestCase {
    
    private let peripheral1 = TestPeripheral(identifier: UUID())
    private let peripheral2 = TestPeripheral(identifier: UUID())
    private let peripheral3 = TestPeripheral(identifier: UUID())
    
    let sonarId1 = Data(base64Encoded: "aGVsbG8K")!
    let sonarId2 = Data(base64Encoded: "Z29vZGJ5ZQo=")!
    let sonarId3 = Data(base64Encoded: "Z29vZGJ5dGUK")!
    
    var listener: TestBTLEListener!
    var persister: ContactEventPersisterDouble!
    var collector: PersistingContactEventRepository!

    override func setUp() {
        listener = TestBTLEListener()
        persister = ContactEventPersisterDouble()
        collector = PersistingContactEventRepository(persister: persister)
    }

    func testLiveUpdatePropertyForDebugViewIsMaintained() {
        collector.btleListener(listener, didFind: sonarId1, forPeripheral: peripheral1)
        collector.btleListener(listener, didFind: sonarId2, forPeripheral: peripheral2)
        collector.btleListener(listener, didFind: sonarId3, forPeripheral: peripheral3)

        XCTAssertEqual(3, collector._contactEventCount)
    }

    func testReadsSonarIdForUnknownPeripheral() {
        collector.btleListener(listener, didReadRSSI: -42, forPeripheral: peripheral1)
        
        XCTAssertEqual(listener.connectedPeripheral?.identifier, peripheral1.identifier)
    }
    
    func testRecordsRSSIValuesAgainstCorrectPeripheral() {
        collector.btleListener(listener, didFind: sonarId1, forPeripheral: peripheral1)

        collector.btleListener(listener, didReadRSSI: 21, forPeripheral: peripheral2)
        collector.btleListener(listener, didReadRSSI: 11, forPeripheral: peripheral1)
        collector.btleListener(listener, didFind: sonarId2, forPeripheral: peripheral2)
        collector.btleListener(listener, didReadRSSI: 31, forPeripheral: peripheral3)
        collector.btleListener(listener, didReadRSSI: 22, forPeripheral: peripheral2)
        collector.btleListener(listener, didReadRSSI: 32, forPeripheral: peripheral3)
        collector.btleListener(listener, didReadRSSI: 23, forPeripheral: peripheral2)
        collector.btleListener(listener, didReadRSSI: 12, forPeripheral: peripheral1)
        collector.btleListener(listener, didReadRSSI: 13, forPeripheral: peripheral1)
        collector.btleListener(listener, didFind: sonarId3, forPeripheral: peripheral3)
        collector.btleListener(listener, didReadRSSI: 33, forPeripheral: peripheral3)
        
        XCTAssertEqual(collector.peripheralIdentifierToContactEvent[peripheral1.identifier]?.rssiValues, [11, 12, 13])
        XCTAssertEqual(collector.peripheralIdentifierToContactEvent[peripheral2.identifier]?.rssiValues, [21, 22, 23])
        XCTAssertEqual(collector.peripheralIdentifierToContactEvent[peripheral3.identifier]?.rssiValues, [31, 32, 33])
    }
    
    func testResetResetsUnderlyingPersister() {
        collector.btleListener(listener, didFind: sonarId1, forPeripheral: peripheral1)
        collector.btleListener(listener, didFind: sonarId2, forPeripheral: peripheral2)
        collector.btleListener(listener, didFind: sonarId3, forPeripheral: peripheral3)

        collector.reset()
        
        XCTAssertEqual(collector.contactEvents.count, 0)
    }

}

fileprivate struct TestPeripheral: BTLEPeripheral {
    let identifier: UUID
}
