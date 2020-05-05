//
//  ContactEventRepositoryTests.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class PersistingContactEventRepositoryTests: XCTestCase {
    
    private let peripheral1 = TestPeripheral(identifier: UUID())
    private let peripheral2 = TestPeripheral(identifier: UUID())
    private let peripheral3 = TestPeripheral(identifier: UUID())
    
    let payload1 = IncomingBroadcastPayload.sample1
    let payload2 = IncomingBroadcastPayload.sample2
    let payload3 = IncomingBroadcastPayload.sample3

    var listener: BTLEListenerDouble!
    var persister: ContactEventPersisterDouble!
    var delegate: MockContactEventRepositoryDelegate!
    var repository: PersistingContactEventRepository!

    override func setUp() {
        listener = BTLEListenerDouble()
        persister = ContactEventPersisterDouble()
        delegate = MockContactEventRepositoryDelegate()
        repository = PersistingContactEventRepository(persister: persister)
        repository.delegate = delegate
    }
    
    func testRecordsTxPowerValuesAgainstCorrectPeripheral() {
        repository.btleListener(listener, didFind: payload1, for: peripheral1)
        repository.btleListener(listener, didReadTxPower: 11, for: peripheral1)
        repository.btleListener(listener, didReadTxPower: 33, for: peripheral3)
        repository.btleListener(listener, didFind: payload2, for: peripheral2)
        repository.btleListener(listener, didFind: payload3, for: peripheral3)
        repository.btleListener(listener, didReadTxPower: 22, for: peripheral2)
        
        XCTAssertEqual(repository.contactEvents.first(where: { $0.broadcastPayload == payload1 })?.txPower, 11)
        XCTAssertEqual(repository.contactEvents.first(where: { $0.broadcastPayload == payload2 })?.txPower, 22)
        XCTAssertEqual(repository.contactEvents.first(where: { $0.broadcastPayload == payload3 })?.txPower, 33)
    }
    
    func testRecordsRSSIValuesAgainstCorrectPeripheral() {
        repository.btleListener(listener, didFind: payload1, for: peripheral1)

        repository.btleListener(listener, didReadRSSI: 21, for: peripheral2)
        repository.btleListener(listener, didReadRSSI: 11, for: peripheral1)
        repository.btleListener(listener, didFind: payload2, for: peripheral2)
        repository.btleListener(listener, didReadRSSI: 31, for: peripheral3)
        repository.btleListener(listener, didReadRSSI: 22, for: peripheral2)
        repository.btleListener(listener, didReadRSSI: 32, for: peripheral3)
        repository.btleListener(listener, didReadRSSI: 23, for: peripheral2)
        repository.btleListener(listener, didReadRSSI: 12, for: peripheral1)
        repository.btleListener(listener, didReadRSSI: 13, for: peripheral1)
        repository.btleListener(listener, didFind: payload3, for: peripheral3)
        repository.btleListener(listener, didReadRSSI: 33, for: peripheral3)
        
        XCTAssertEqual(repository.contactEvents.first(where: { $0.broadcastPayload == payload1 })?.rssiValues, [11, 12, 13])
        XCTAssertEqual(repository.contactEvents.first(where: { $0.broadcastPayload == payload2 })?.rssiValues, [21, 22, 23])
        XCTAssertEqual(repository.contactEvents.first(where: { $0.broadcastPayload == payload3 })?.rssiValues, [31, 32, 33])
        
        XCTAssertEqual(delegate.broadcastIds[peripheral1.identifier], payload1)
        XCTAssertEqual(delegate.broadcastIds[peripheral2.identifier], payload2)
        XCTAssertEqual(delegate.broadcastIds[peripheral3.identifier], payload3)
        XCTAssertEqual(delegate.rssiValues[peripheral1.identifier], [11, 12, 13])
        XCTAssertEqual(delegate.rssiValues[peripheral2.identifier], [21, 22, 23])
        XCTAssertEqual(delegate.rssiValues[peripheral3.identifier], [31, 32, 33])
    }
    
    func testResetResetsUnderlyingPersister() {
        repository.btleListener(listener, didFind: payload1, for: peripheral1)
        repository.btleListener(listener, didFind: payload2, for: peripheral2)
        repository.btleListener(listener, didFind: payload3, for: peripheral3)

        repository.reset()
        
        XCTAssertEqual(repository.contactEvents.count, 0)
    }
    
    func testUpdatesWithItemsMoreRecentThan28Days() {
        repository.btleListener(listener, didFind: payload2, for: peripheral2)
        repository.btleListener(listener, didFind: payload3, for: peripheral3)
        
        persister.items[peripheral1.identifier] = ContactEvent(
            broadcastPayload: payload1,
            timestamp: Date(timeIntervalSinceNow: -2419300),
            rssiValues: [],
            rssiIntervals: [],
            duration: 0
        )
        
        repository.removeExpiredContactEvents(ttl: 2419200)
        XCTAssertEqual(repository.contactEvents.count, 2)
    }

    func testRemoveContactEventsUntil() {
        repository.btleListener(listener, didFind: payload1, for: peripheral1)
        repository.btleListener(listener, didFind: payload2, for: peripheral2)
        repository.btleListener(listener, didFind: payload3, for: peripheral3)

        guard let contactEvent = persister.items[peripheral2.identifier] else {
            XCTFail("Contact event for \(peripheral2.identifier) not found")
            return
        }

        repository.remove(through: contactEvent.timestamp)

        XCTAssertEqual(repository.contactEvents.count, 1)
    }
    
    func testSerialisationFormatDoesNotChange() throws {
        // If this test fails something happened (maybe a rename, maybe addition or deletion of a field)
        // which changed the serialization format on disk. Since we're now live, you need to make sure
        // a migration is added (and tested!) that can migrate from *every past serialised version* of
        // the on-disk data to the current version.
        
        let fileURL = Bundle(for: type(of: self)).url(forResource: "build341_contactEvents", withExtension: "plist")!
        let persister_build341 = PlistPersister<UUID, ContactEvent>(fileURL: fileURL)
        
        XCTAssertEqual(persister_build341.items.count, 2)
    }

}

fileprivate struct TestPeripheral: BTLEPeripheral {
    let identifier: UUID
}

class MockContactEventRepositoryDelegate: ContactEventRepositoryDelegate {
    
    var broadcastIds: [UUID: IncomingBroadcastPayload] = [:]
    var rssiValues: [UUID: [Int]] = [:]
    
    func repository(_ repository: ContactEventRepository, didRecord broadcastPayload: IncomingBroadcastPayload, for peripheral: BTLEPeripheral) {
        broadcastIds[peripheral.identifier] = broadcastPayload
    }
    
    func repository(_ repository: ContactEventRepository, didRecordRSSI RSSI: Int, for peripheral: BTLEPeripheral) {
        if rssiValues[peripheral.identifier] == nil {
            rssiValues[peripheral.identifier] = []
        }
        rssiValues[peripheral.identifier]?.append(RSSI)
    }
    
}
