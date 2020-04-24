//
//  ContactEventUploaderTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class ContactEventsUploaderTests: XCTestCase {

    #warning("Make sure this case is handled before we ship a public release")
    func testNotRegistered() throws {
        throw XCTSkip("TODO: write this test")
    }

    func testUploadRequest() {
        let registration = Registration.fake
        let persisting = PersistenceDouble(registration: registration)
        let expectedBroadcastId = "opaque bytes that only the server can decrypt".data(using: .utf8)!
        let contactEvent = ContactEvent(encryptedRemoteContactId: expectedBroadcastId)
        let contactEventRepository = ContactEventRepositoryDouble()
        contactEventRepository.contactEvents = [contactEvent]
        let session = SessionDouble()

        let uploader = ContactEventsUploader(
            persisting: persisting,
            contactEventRepository: contactEventRepository,
            makeSession: { _, _ in session }
        )

        try? uploader.upload()

        guard
            let request = session.uploadRequest as? PatchContactEventsRequest
        else {
            XCTFail("Expected a PatchContactEventsRequest but got \(String(describing: session.requestSent))")
            return
        }

        XCTAssertEqual(request.path, "/api/residents/\(registration.id.uuidString)")

        switch request.method {
        case .patch(let data):
            let decoder = JSONDecoder()
            let decoded = try? decoder.decode([String: [DecodableBroadcastId]].self, from: data)
            // Can't compare the entire contact events because the timestamp loses precision
            // when JSON encoded and decoded.

            XCTAssertEqual(1, decoded?.count)

            let firstEvent = decoded?["contactEvents"]?.first
            XCTAssertEqual(expectedBroadcastId, firstEvent?.encryptedRemoteContactId)
        default:
            XCTFail("Expected a patch request but got \(request.method)")
        }
    }

    func testUploadLogRequestedAndStarted() {
        let registration = Registration.fake
        let persisting = PersistenceDouble(registration: registration)
        let expectedBroadcastId = "opaque bytes that only the server can decrypt".data(using: .utf8)!
        let contactEvent = ContactEvent(encryptedRemoteContactId: expectedBroadcastId)
        let contactEventRepository = ContactEventRepositoryDouble()
        contactEventRepository.contactEvents = [contactEvent]
        let session = SessionDouble()

        let uploader = ContactEventsUploader(
            persisting: persisting,
            contactEventRepository: contactEventRepository,
            makeSession: { _, _ in session }
        )

        try? uploader.upload()

        let uploadLog = persisting.uploadLog
        XCTAssertEqual(uploadLog.first?.event, .requested)

        guard case .started = uploadLog.last?.event else {
            XCTFail("Expected a started event")
            return
        }
    }

    func testCleanup() {
        let registration = Registration.fake
        let persisting = PersistenceDouble(registration: registration)
        let expectedBroadcastId = "opaque bytes that only the server can decrypt".data(using: .utf8)!
        let contactEvent = ContactEvent(encryptedRemoteContactId: expectedBroadcastId)
        let contactEventRepository = ContactEventRepositoryDouble()
        contactEventRepository.contactEvents = [contactEvent]
        let session = SessionDouble()

        let uploader = ContactEventsUploader(
            persisting: persisting,
            contactEventRepository: contactEventRepository,
            makeSession: { _, _ in session }
        )

        try? uploader.upload()
        uploader.cleanup()

        XCTAssertEqual(contactEventRepository.removedThroughDate, contactEvent.timestamp)

        guard case .completed = persisting.uploadLog.last?.event else {
            XCTFail("Expected a completed log")
            return
        }
    }

}
