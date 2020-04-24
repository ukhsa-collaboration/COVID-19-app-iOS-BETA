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
    
    let broadcastId1 = Data(base64Encoded: "aGVsbG8K")!
    let broadcastId2 = Data(base64Encoded: "Z29vZGJ5ZQo=")!
    let broadcastId3 = Data(base64Encoded: "Z29vZGJ5dGUK")!
    
    var listener: BTLEListenerDouble!
    var persister: ContactEventPersisterDouble!
    var repository: PersistingContactEventRepository!

    override func setUp() {
        listener = BTLEListenerDouble()
        persister = ContactEventPersisterDouble()
        repository = PersistingContactEventRepository(persister: persister)
    }

    func testLiveUpdatePropertyForDebugViewIsMaintained() {
        repository.btleListener(listener, didFind: broadcastId1, forPeripheral: peripheral1)
        repository.btleListener(listener, didFind: broadcastId2, forPeripheral: peripheral2)
        repository.btleListener(listener, didFind: broadcastId3, forPeripheral: peripheral3)

        XCTAssertEqual(3, repository._contactEventCount)
    }

    func testReadsSonarIdForUnknownPeripheral() {
        repository.btleListener(listener, didReadRSSI: -42, forPeripheral: peripheral1)
        
        XCTAssertEqual(listener.connectedPeripheral?.identifier, peripheral1.identifier)
    }
    
    func testRecordsRSSIValuesAgainstCorrectPeripheral() {
        repository.btleListener(listener, didFind: broadcastId1, forPeripheral: peripheral1)

        repository.btleListener(listener, didReadRSSI: 21, forPeripheral: peripheral2)
        repository.btleListener(listener, didReadRSSI: 11, forPeripheral: peripheral1)
        repository.btleListener(listener, didFind: broadcastId2, forPeripheral: peripheral2)
        repository.btleListener(listener, didReadRSSI: 31, forPeripheral: peripheral3)
        repository.btleListener(listener, didReadRSSI: 22, forPeripheral: peripheral2)
        repository.btleListener(listener, didReadRSSI: 32, forPeripheral: peripheral3)
        repository.btleListener(listener, didReadRSSI: 23, forPeripheral: peripheral2)
        repository.btleListener(listener, didReadRSSI: 12, forPeripheral: peripheral1)
        repository.btleListener(listener, didReadRSSI: 13, forPeripheral: peripheral1)
        repository.btleListener(listener, didFind: broadcastId3, forPeripheral: peripheral3)
        repository.btleListener(listener, didReadRSSI: 33, forPeripheral: peripheral3)
        
        XCTAssertEqual(repository.contactEvents.first(where: { $0.encryptedRemoteContactId == broadcastId1 })?.rssiValues, [11, 12, 13])
        XCTAssertEqual(repository.contactEvents.first(where: { $0.encryptedRemoteContactId == broadcastId2 })?.rssiValues, [21, 22, 23])
        XCTAssertEqual(repository.contactEvents.first(where: { $0.encryptedRemoteContactId == broadcastId3 })?.rssiValues, [31, 32, 33])
    }
    
    func testResetResetsUnderlyingPersister() {
        repository.btleListener(listener, didFind: broadcastId1, forPeripheral: peripheral1)
        repository.btleListener(listener, didFind: broadcastId2, forPeripheral: peripheral2)
        repository.btleListener(listener, didFind: broadcastId3, forPeripheral: peripheral3)

        repository.reset()
        
        XCTAssertEqual(repository.contactEvents.count, 0)
    }
    
    func testUpdatesWithItemsMoreRecentThan28Days() {
        repository.btleListener(listener, didFind: broadcastId2, forPeripheral: peripheral2)
        repository.btleListener(listener, didFind: broadcastId3, forPeripheral: peripheral3)
        
        persister.items[peripheral1.identifier] = ContactEvent(
            encryptedRemoteContactId: broadcastId1,
            timestamp: Date(timeIntervalSinceNow: -2419300),
            rssiValues: [],
            rssiIntervals: [],
            duration: 0
        )
        
        repository.removeExpiredContactEvents(ttl: 2419200)
        XCTAssertEqual(repository.contactEvents.count, 2)
    }

    func testRemoveContactEventsUntil() {
        repository.btleListener(listener, didFind: broadcastId1, forPeripheral: peripheral1)
        repository.btleListener(listener, didFind: broadcastId2, forPeripheral: peripheral2)
        repository.btleListener(listener, didFind: broadcastId3, forPeripheral: peripheral3)

        guard let contactEvent = persister.items[peripheral2.identifier] else {
            XCTFail("Contact event for \(peripheral2.identifier) not found")
            return
        }

        repository.remove(through: contactEvent.timestamp)

        XCTAssertEqual(repository.contactEvents.count, 1)
    }

}

fileprivate struct TestPeripheral: BTLEPeripheral {
    let identifier: UUID
}
