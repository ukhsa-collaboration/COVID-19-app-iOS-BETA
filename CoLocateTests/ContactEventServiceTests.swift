//
//  ContactEventServiceTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class ContactEventServiceTests: XCTestCase {

    let contactEvent1 = ContactEvent(uuid: UUID())
    let contactEvent2 = ContactEvent(uuid: UUID())
    let contactEvent3 = ContactEvent(uuid: UUID())
    
    var service: ContactEventRecorder!

    override func setUp() {
        service = CodableContactEventRecorder.shared
    }

    override func tearDown() {
        service.reset()
    }

    func testRecordsContactEvents() {
        XCTAssertEqual(service.contactEvents, [])

        service.record(contactEvent1)
        service.record(contactEvent2)
        service.record(contactEvent3)

        XCTAssertEqual(service.contactEvents.count, 3)
        XCTAssertEqual(service.contactEvents[0], contactEvent1)
        XCTAssertEqual(service.contactEvents[1], contactEvent2)
        XCTAssertEqual(service.contactEvents[2], contactEvent3)
    }

    func testPersistsContactEvents() {
        let url = CodableContactEventRecorder.archiveURL
    
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))

        service.record(contactEvent1)
        service.record(contactEvent2)
        service.record(contactEvent3)

        let attrs = try! FileManager.default.attributesOfItem(atPath: url.path)
        XCTAssertNotEqual(attrs[.size] as! NSNumber, 0)
    }

    func testLoadsContactEventsFromDiskOnInit() {
        service.record(contactEvent1)
        service.record(contactEvent2)
        service.record(contactEvent3)

        service = nil

        service = CodableContactEventRecorder()
        XCTAssertEqual(service.contactEvents.count, 3)
    }
}
