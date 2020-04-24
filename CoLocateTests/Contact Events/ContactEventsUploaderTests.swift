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

    var overAnHourAgo: Date!

    override func setUp() {
        super.setUp()

        overAnHourAgo = Date() - (60 * 60 + 1)
    }

    func testNotRegistered() throws {
        let persisting = PersistenceDouble()
        let contactEventRepository = ContactEventRepositoryDouble()
        let session = SessionDouble()

        let uploader = ContactEventsUploader(
            persisting: persisting,
            contactEventRepository: contactEventRepository,
            makeSession: { _, _ in session }
        )

        try? uploader.upload()

        XCTAssertEqual(persisting.uploadLog.map { $0.event }, [.requested])
        XCTAssertNil(session.uploadRequest)
    }

    func testUploadRequest() {
        let registration = Registration.fake
        let persisting = PersistenceDouble(
            diagnosis: SelfDiagnosis(symptoms: [], startDate: Date()),
            registration: registration
        )
        let expectedBroadcastId = "opaque bytes that only the server can decrypt".data(using: .utf8)!
        let contactEvent = ContactEvent(encryptedRemoteContactId: expectedBroadcastId)
        let contactEventRepository = ContactEventRepositoryDouble(contactEvents: [contactEvent])
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
            decoder.dateDecodingStrategy = .iso8601

            let decoded = try? decoder.decode(PatchContactEventsRequest.JSONWrapper.self, from: data)

            // Can't compare the entire contact events because the timestamp loses precision
            // when JSON encoded and decoded.

            XCTAssertEqual(1, decoded?.contactEvents.count)

            let firstEvent = decoded?.contactEvents.first
            XCTAssertEqual(expectedBroadcastId, firstEvent?.encryptedRemoteContactId)
        default:
            XCTFail("Expected a patch request but got \(request.method)")
        }
    }

    func testUploadLogRequestedAndStarted() {
        let registration = Registration.fake
        let persisting = PersistenceDouble(
            diagnosis: SelfDiagnosis(symptoms: [], startDate: Date()),
            registration: registration
        )
        let expectedBroadcastId = "opaque bytes that only the server can decrypt".data(using: .utf8)!
        let contactEvent = ContactEvent(encryptedRemoteContactId: expectedBroadcastId)
        let contactEventRepository = ContactEventRepositoryDouble(contactEvents: [contactEvent])
        let session = SessionDouble()

        let uploader = ContactEventsUploader(
            persisting: persisting,
            contactEventRepository: contactEventRepository,
            makeSession: { _, _ in session }
        )

        try? uploader.upload()

        XCTAssertEqual(persisting.uploadLog.map { $0.event.key }, ["requested", "started"])
    }

    func testCleanup() {
        let registration = Registration.fake
        let persisting = PersistenceDouble(
            diagnosis: SelfDiagnosis(symptoms: [], startDate: Date()),
            registration: registration
        )
        let expectedBroadcastId = "opaque bytes that only the server can decrypt".data(using: .utf8)!
        let contactEvent = ContactEvent(encryptedRemoteContactId: expectedBroadcastId)
        let contactEventRepository = ContactEventRepositoryDouble(contactEvents: [contactEvent])
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

    func testEnsureUploadingWhenRequestedButNoRegistration() {
        let persisting = PersistenceDouble(
            diagnosis: SelfDiagnosis(symptoms: [], startDate: Date()),
            uploadLog: [UploadLog(event: .requested)]
        )
        let contactEventRepository = ContactEventRepositoryDouble()
        let session = SessionDouble()

        let uploader = ContactEventsUploader(
            persisting: persisting,
            contactEventRepository: contactEventRepository,
            makeSession: { _, _ in session }
        )

        try? uploader.ensureUploading()

        XCTAssertEqual(persisting.uploadLog.map { $0.event }, [.requested])
        XCTAssertNil(session.uploadRequest)
    }

    func testEnsureUploadingWhenRequestedWithRegistration() {
        let registration = Registration.fake
        let persisting = PersistenceDouble(
            diagnosis: SelfDiagnosis(symptoms: [], startDate: Date()),
            registration: registration,
            uploadLog: [UploadLog(date: overAnHourAgo, event: .requested)]
        )
        let contactEventRepository = ContactEventRepositoryDouble()
        let session = SessionDouble()

        let uploader = ContactEventsUploader(
            persisting: persisting,
            contactEventRepository: contactEventRepository,
            makeSession: { _, _ in session }
        )

        try? uploader.ensureUploading()

        XCTAssertEqual(persisting.uploadLog.map { $0.event.key }, ["requested", "started"])
        XCTAssertNotNil(session.uploadRequest)
    }

    func testEnsureUploadingWhenStarted() {
        let registration = Registration.fake
        let persisting = PersistenceDouble(
            diagnosis: SelfDiagnosis(symptoms: [], startDate: Date()),
            registration: registration,
            uploadLog: [
                UploadLog(event: .requested),
                UploadLog(event: .started(lastContactEventDate: Date())),
            ]
        )
        let contactEventRepository = ContactEventRepositoryDouble()
        let session = SessionDouble()

        let uploader = ContactEventsUploader(
            persisting: persisting,
            contactEventRepository: contactEventRepository,
            makeSession: { _, _ in session }
        )

        try? uploader.ensureUploading()

        XCTAssertEqual(persisting.uploadLog.map { $0.event.key }, ["requested", "started"])
        XCTAssertNil(session.uploadRequest)
    }

    func testEnsureUploadingWhenCompleted() {
        let registration = Registration.fake
        let persisting = PersistenceDouble(
            diagnosis: SelfDiagnosis(symptoms: [], startDate: Date()),
            registration: registration,
            uploadLog: [
                UploadLog(event: .requested),
                UploadLog(event: .started(lastContactEventDate: Date())),
                UploadLog(event: .completed(error: nil)),
            ]
        )
        let contactEventRepository = ContactEventRepositoryDouble()
        let session = SessionDouble()

        let uploader = ContactEventsUploader(
            persisting: persisting,
            contactEventRepository: contactEventRepository,
            makeSession: { _, _ in session }
        )

        try? uploader.ensureUploading()

        XCTAssertEqual(persisting.uploadLog.map { $0.event.key }, ["requested", "started", "completed"])
        XCTAssertNil(session.uploadRequest)
    }

    func testEnsureUploadingWhenError() {
        let registration = Registration.fake
        let persisting = PersistenceDouble(
            diagnosis: SelfDiagnosis(symptoms: [], startDate: Date()),
            registration: registration,
            uploadLog: [
                UploadLog(event: .requested),
                UploadLog(event: .started(lastContactEventDate: Date())),
                UploadLog(date: overAnHourAgo, event: .completed(error: "oh no")),
            ]
        )
        let contactEventRepository = ContactEventRepositoryDouble()
        let session = SessionDouble()

        let uploader = ContactEventsUploader(
            persisting: persisting,
            contactEventRepository: contactEventRepository,
            makeSession: { _, _ in session }
        )

        try? uploader.ensureUploading()

        XCTAssertEqual(persisting.uploadLog.map { $0.event.key }, ["requested", "started", "completed", "started"])
        XCTAssertNotNil(session.uploadRequest)
    }

    func testEnsureUploadingBeforeAnHourHasPassed() {
        let registration = Registration.fake
        let persisting = PersistenceDouble(
            diagnosis: SelfDiagnosis(symptoms: [], startDate: Date()),
            registration: registration,
            uploadLog: [
                UploadLog(event: .requested),
            ]
        )
        let contactEventRepository = ContactEventRepositoryDouble()
        let session = SessionDouble()

        let uploader = ContactEventsUploader(
            persisting: persisting,
            contactEventRepository: contactEventRepository,
            makeSession: { _, _ in session }
        )

        try? uploader.ensureUploading()

        XCTAssertEqual(persisting.uploadLog.map { $0.event.key }, ["requested"])
        XCTAssertNil(session.uploadRequest)
    }

}
