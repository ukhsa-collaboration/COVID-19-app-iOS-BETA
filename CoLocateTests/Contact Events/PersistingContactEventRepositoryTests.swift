//
//  ContactEventRepositoryTests.swift
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
    var repository: PersistingContactEventRepository!

    override func setUp() {
        listener = TestBTLEListener()
        persister = ContactEventPersisterDouble()
        repository = PersistingContactEventRepository(persister: persister)
    }

    func testLiveUpdatePropertyForDebugViewIsMaintained() {
        repository.btleListener(listener, didFind: sonarId1, forPeripheral: peripheral1)
        repository.btleListener(listener, didFind: sonarId2, forPeripheral: peripheral2)
        repository.btleListener(listener, didFind: sonarId3, forPeripheral: peripheral3)

        XCTAssertEqual(3, repository._contactEventCount)
    }

    func testReadsSonarIdForUnknownPeripheral() {
        repository.btleListener(listener, didReadRSSI: -42, forPeripheral: peripheral1)
        
        XCTAssertEqual(listener.connectedPeripheral?.identifier, peripheral1.identifier)
    }
    
    func testRecordsRSSIValuesAgainstCorrectPeripheral() {
        repository.btleListener(listener, didFind: sonarId1, forPeripheral: peripheral1)

        repository.btleListener(listener, didReadRSSI: 21, forPeripheral: peripheral2)
        repository.btleListener(listener, didReadRSSI: 11, forPeripheral: peripheral1)
        repository.btleListener(listener, didFind: sonarId2, forPeripheral: peripheral2)
        repository.btleListener(listener, didReadRSSI: 31, forPeripheral: peripheral3)
        repository.btleListener(listener, didReadRSSI: 22, forPeripheral: peripheral2)
        repository.btleListener(listener, didReadRSSI: 32, forPeripheral: peripheral3)
        repository.btleListener(listener, didReadRSSI: 23, forPeripheral: peripheral2)
        repository.btleListener(listener, didReadRSSI: 12, forPeripheral: peripheral1)
        repository.btleListener(listener, didReadRSSI: 13, forPeripheral: peripheral1)
        repository.btleListener(listener, didFind: sonarId3, forPeripheral: peripheral3)
        repository.btleListener(listener, didReadRSSI: 33, forPeripheral: peripheral3)
        
        XCTAssertEqual(repository.contactEvents.first(where: { $0.sonarId == sonarId1 })?.rssiValues, [11, 12, 13])
        XCTAssertEqual(repository.contactEvents.first(where: { $0.sonarId == sonarId2 })?.rssiValues, [21, 22, 23])
        XCTAssertEqual(repository.contactEvents.first(where: { $0.sonarId == sonarId3 })?.rssiValues, [31, 32, 33])
    }
    
    func testResetResetsUnderlyingPersister() {
        repository.btleListener(listener, didFind: sonarId1, forPeripheral: peripheral1)
        repository.btleListener(listener, didFind: sonarId2, forPeripheral: peripheral2)
        repository.btleListener(listener, didFind: sonarId3, forPeripheral: peripheral3)

        repository.reset()
        
        XCTAssertEqual(repository.contactEvents.count, 0)
    }
    
    func testUpdatesWithItemsMoreRecentThan28Days() {
        repository.btleListener(listener, didFind: sonarId2, forPeripheral: peripheral2)
        repository.btleListener(listener, didFind: sonarId3, forPeripheral: peripheral3)
        
        persister.items[peripheral1.identifier] = ContactEvent(
            sonarId: sonarId1,
            timestamp: Date(timeIntervalSinceNow: -2419300),
            rssiValues: [],
            rssiIntervals: [],
            duration: 0
        )
        
        repository.update()
        XCTAssertEqual(persister.updateCount, 2)
    }
    
}

fileprivate struct TestPeripheral: BTLEPeripheral {
    let identifier: UUID
}
