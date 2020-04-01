//
//  ContactEventServiceTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class PlistContactEventRecorderTests: XCTestCase {

    let epoch = Date(timeIntervalSince1970: 0)
    
    var contactEvent1: OldContactEvent!
    var contactEvent2: OldContactEvent!
    var contactEvent3: OldContactEvent!
    
    var service: PlistContactEventRecorder!

    override func setUp() {
        super.setUp()

        service = PlistContactEventRecorder()
        service.reset()
        
        contactEvent1 = OldContactEvent(remoteContactId: UUID(), timestamp: epoch, rssi: 1)
        contactEvent2 = OldContactEvent(remoteContactId: UUID(), timestamp: epoch, rssi: 1)
        contactEvent3 = OldContactEvent(remoteContactId: UUID(), timestamp: epoch, rssi: 1)
    }

    func testRecordsContactEvents() {
        XCTAssertEqual(service.oldContactEvents, [])

        service.record(contactEvent1)
        service.record(contactEvent2)
        service.record(contactEvent3)

        XCTAssertEqual(service.oldContactEvents.count, 3)
        XCTAssertEqual(service.oldContactEvents[0], contactEvent1)
        XCTAssertEqual(service.oldContactEvents[1], contactEvent2)
        XCTAssertEqual(service.oldContactEvents[2], contactEvent3)
    }

    func testPersistsContactEvents() {
        XCTAssertFalse(FileManager.default.fileExists(atPath: service.fileURL.path))

        service.record(contactEvent1)
        service.record(contactEvent2)
        service.record(contactEvent3)

        let attrs = try! FileManager.default.attributesOfItem(atPath: service.fileURL.path)
        XCTAssertNotEqual(attrs[.size] as! NSNumber, 0)
    }

    func testLoadsContactEventsFromDiskOnInit() {
        service.record(contactEvent1)
        service.record(contactEvent2)
        service.record(contactEvent3)

        service = nil

        service = PlistContactEventRecorder()
        XCTAssertEqual(service.oldContactEvents.count, 3)
    }

}
