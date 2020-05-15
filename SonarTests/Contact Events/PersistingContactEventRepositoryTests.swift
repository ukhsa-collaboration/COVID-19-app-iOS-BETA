//
//  ContactEventRepositoryTests.swift
//  SonarTests
//
//  Created by NHSX on 31.03.20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class PersistingContactEventRepositoryTests: XCTestCase {
    
    private let peripheral1 = TestPeripheral(identifier: UUID())
    private let peripheral2 = TestPeripheral(identifier: UUID())
    private let peripheral3 = TestPeripheral(identifier: UUID())
    
    private let payload1 = IncomingBroadcastPayload.sample1
    private let payload2 = IncomingBroadcastPayload.sample2
    private let payload3 = IncomingBroadcastPayload.sample3

    private var listener: BTLEListenerDouble!
    private var persister: ContactEventPersisterDouble!
    private var delegate: MockContactEventRepositoryDelegate!
    private var repository: PersistingContactEventRepository!

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
    
    func testNewPeripheralWithSameBroadcastIdRecordsValuesAgainstExistingContactEvent() throws {
        repository.btleListener(listener, didReadTxPower: 1, for: peripheral1)
        repository.btleListener(listener, didFind: payload1, for: peripheral1)
        repository.btleListener(listener, didReadRSSI: 11, for: peripheral1)
        repository.btleListener(listener, didReadRSSI: 12, for: peripheral1)
        repository.btleListener(listener, didReadRSSI: 22, for: peripheral2)
        repository.btleListener(listener, didReadTxPower: 2, for: peripheral2)
        repository.btleListener(listener, didFind: payload1, for: peripheral2)
        repository.btleListener(listener, didReadRSSI: 23, for: peripheral2)
        repository.btleListener(listener, didReadRSSI: 24, for: peripheral2)
        
        XCTAssertEqual(repository.contactEvents.count, 1)
        let contactEvent = repository.contactEvents.first(where: { $0.broadcastPayload == payload1 })
        XCTAssertEqual(contactEvent?.broadcastPayload, payload1)
        XCTAssertEqual(contactEvent?.txPower, 2)
        XCTAssertEqual(contactEvent?.rssiValues, [11, 12, 22, 23, 24])
    }
    
    func testNewBroadcastIdForSamePeripheralCreatesNewContactEvent() throws {
        repository.btleListener(listener, didReadTxPower: 42, for: peripheral1)
        repository.btleListener(listener, didFind: payload1, for: peripheral1)
        repository.btleListener(listener, didReadRSSI: 11, for: peripheral1)
        repository.btleListener(listener, didReadRSSI: 22, for: peripheral1)
        repository.btleListener(listener, didFind: payload2, for: peripheral1)
        repository.btleListener(listener, didReadRSSI: 33, for: peripheral1)
        repository.btleListener(listener, didReadRSSI: 44, for: peripheral1)
        
        XCTAssertEqual(repository.contactEvents.count, 2)
        
        let contactEvent1 = repository.contactEvents.first(where: { $0.broadcastPayload == payload1 })
        XCTAssertEqual(contactEvent1?.txPower, 42)
        XCTAssertEqual(contactEvent1?.rssiValues, [11, 22])
        
        let contactEvent2 = repository.contactEvents.first(where: { $0.broadcastPayload == payload2 })
        XCTAssertEqual(contactEvent2?.txPower, 42)
        XCTAssertEqual(contactEvent2?.rssiValues, [33, 44])
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
        
        persister.update(
            item: ContactEvent(timestamp: Date(timeIntervalSinceNow: -2419300)),
            key: peripheral1.identifier
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

    // If any of these tests fail something happened (maybe a rename, maybe addition or deletion of
    // a field) which changed the serialization format on disk. Since we're now live, you need to make
    // sure a migration is added (and tested!) that can migrate from *every past serialised version* of
    // the on-disk data to the current version.

    func testSerialisedDataIsReadable_V1_0_1_build_341() throws {
        
        let fileURL = Bundle(for: type(of: self)).url(forResource: "build341_contactEvents", withExtension: "plist")!
        let persister_build341 = PlistPersister<UUID, ContactEvent>(fileURL: fileURL)
        
        XCTAssertEqual(persister_build341.items.count, 2)
    }

    func testSerialisedDataIsReadable_V1_0_2_build_356() throws {
        throw XCTSkip("TODO: add this soon")
        XCTFail("Add test with sample of file from build 356")
    }

    func testSerialisedDataIsReadable_current() throws {
        throw XCTSkip("TODO: add this soon")
        XCTFail("Add test with sample of file from head after 356")
    }

}

// Verify that the PersistingContactEventRepository and the persistence layer work together
// to write the correct data to disk.
class PersistingContactEventRepositoryFocusedIntegrationTests: XCTestCase {
    func testPersistsBroadcastPayload() {
        let filename = "testPersistsBroadcastPayload"
        let persister = PlistPersister<UUID, ContactEvent>(fileName: filename)
        persister.reset()
        XCTAssertFalse(FileManager.default.fileExists(atPath: persister.fileURL.path))
        let repository = PersistingContactEventRepository(persister: persister)
        
        let payload = IncomingBroadcastPayload.sample1
        let peripheral = TestPeripheral(identifier: UUID())
        repository.btleListener(BTLEListenerDouble(), didFind: payload, for: peripheral)
        
        let reader = PlistPersister<UUID, ContactEvent>(fileName: filename)
        XCTAssertEqual(reader.items[peripheral.identifier]?.broadcastPayload, payload)
    }
    
    func testPersistsTxPower() {
        let filename = "testPersistsTxPower"
        let persister = PlistPersister<UUID, ContactEvent>(fileName: filename)
        persister.reset()
        XCTAssertFalse(FileManager.default.fileExists(atPath: persister.fileURL.path))
        let repository = PersistingContactEventRepository(persister: persister)
        
        let peripheral = TestPeripheral(identifier: UUID())
        repository.btleListener(BTLEListenerDouble(), didReadTxPower: 42, for: peripheral)
        
        let reader = PlistPersister<UUID, ContactEvent>(fileName: filename)
        XCTAssertEqual(reader.items[peripheral.identifier]?.txPower, 42)
    }
    
    func testPersistsRSSI() {
        let filename = "testPersistsRSSI"
        let persister = PlistPersister<UUID, ContactEvent>(fileName: filename)
        persister.reset()
        XCTAssertFalse(FileManager.default.fileExists(atPath: persister.fileURL.path))
        let repository = PersistingContactEventRepository(persister: persister)
        
        let peripheral = TestPeripheral(identifier: UUID())
        repository.btleListener(BTLEListenerDouble(), didReadRSSI: -42, for: peripheral)
        
        let reader = PlistPersister<UUID, ContactEvent>(fileName: filename)
        XCTAssertEqual(reader.items[peripheral.identifier]?.rssiValues, [-42])
    }
}

fileprivate struct TestPeripheral: BTLEPeripheral {
    let identifier: UUID
}

fileprivate class MockContactEventRepositoryDelegate: ContactEventRepositoryDelegate {
    
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
