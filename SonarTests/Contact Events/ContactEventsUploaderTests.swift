//
//  ContactEventUploaderTests.swift
//  SonarTests
//
//  Created by NHSX on 4/22/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

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

        let startDate = Date()
        let symptoms: Symptoms = [.temperature]
        try uploader.upload(from: startDate, with: symptoms)

        let requested = UploadLog.Requested(startDate: startDate, symptoms: symptoms)
        XCTAssertEqual(persisting.uploadLog.map { $0.event }, [.requested(requested)])
        XCTAssertNil(session.uploadRequest)
    }

    func testUploadRequest() throws {
        let registration = Registration.fake
        let persisting = PersistenceDouble(registration: registration)
        let payload = IncomingBroadcastPayload.sample1
        let contactEvent = ContactEvent(broadcastPayload: payload)
        let contactEventRepository = ContactEventRepositoryDouble(contactEvents: [contactEvent])
        let session = SessionDouble()

        let uploader = ContactEventsUploader(
            persisting: persisting,
            contactEventRepository: contactEventRepository,
            makeSession: { _, _ in session }
        )

        // Arbitrary date since we're round-tripping through JSON and lose precision
        // that we use later for equality.
        let startDate = Calendar.current.date(from: DateComponents(month: 4, day: 1))!
        try uploader.upload(from: startDate, with: [.temperature, .nausea])

        let request = try XCTUnwrap(session.uploadRequest as? UploadProximityEventsRequest)

        XCTAssertEqual(request.urlable, .path("/api/proximity-events/upload"))

        XCTAssertTrue(request.isMethodPATCH)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let data = try XCTUnwrap(request.body)
        let decoded = try decoder.decode(UploadProximityEventsRequest.Wrapper.self, from: data)

        XCTAssertEqual(Set(decoded.symptoms), Set(["TEMPERATURE", "NAUSEA"]))
        XCTAssertEqual(decoded.symptomsTimestamp, startDate)

        // Can't compare the entire contact events because the timestamp loses precision
        // when JSON encoded and decoded.
        XCTAssertEqual(1, decoded.contactEvents.count)

        let firstEvent = decoded.contactEvents.first
        XCTAssertEqual(payload.cryptogram, firstEvent!.encryptedRemoteContactId)
    }

    func testUploadLogRequestedAndStarted() throws {
        let registration = Registration.fake
        let persisting = PersistenceDouble(registration: registration)
        let payload = IncomingBroadcastPayload.sample1
        let contactEvent = ContactEvent(broadcastPayload: payload)
        let contactEventRepository = ContactEventRepositoryDouble(contactEvents: [contactEvent])
        let session = SessionDouble()

        let uploader = ContactEventsUploader(
            persisting: persisting,
            contactEventRepository: contactEventRepository,
            makeSession: { _, _ in session }
        )

        let startDate = Date()
        try uploader.upload(from: startDate, with: [.temperature])

        XCTAssertEqual(persisting.uploadLog.map { $0.event.key }, ["requested", "started"])
    }

    func testCleanup() throws {
        let registration = Registration.fake
        let persisting = PersistenceDouble(registration: registration)
        let payload = IncomingBroadcastPayload.sample1
        let contactEvent = ContactEvent(broadcastPayload: payload)
        let contactEventRepository = ContactEventRepositoryDouble(contactEvents: [contactEvent])
        let session = SessionDouble()

        let uploader = ContactEventsUploader(
            persisting: persisting,
            contactEventRepository: contactEventRepository,
            makeSession: { _, _ in session }
        )

        try uploader.upload(from: Date(), with: [.temperature])
        uploader.cleanup()

        XCTAssertEqual(contactEventRepository.removedThroughDate, contactEvent.timestamp)

        guard case .completed = persisting.uploadLog.last?.event else {
            XCTFail("Expected a completed log")
            return
        }
    }

    func testEnsureUploadingWhenRequestedButNoRegistration() {
        let startDate = Date()
        let requested = UploadLog.Requested(startDate: startDate, symptoms: [.temperature])
        let persisting = PersistenceDouble(
            uploadLog: [
                UploadLog(event: .requested(requested)),
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

        XCTAssertEqual(persisting.uploadLog.map { $0.event }, [.requested(requested)])
        XCTAssertNil(session.uploadRequest)
    }

    func testEnsureUploadingWhenRequestedWithRegistration() {
        let registration = Registration.fake
        let requested = UploadLog.Requested(startDate: Date(), symptoms: [.temperature])
        let persisting = PersistenceDouble(
            registration: registration,
            uploadLog: [
                UploadLog(date: overAnHourAgo, event: .requested(requested)),
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
        XCTAssertNotNil(session.uploadRequest)
    }

    func testEnsureUploadingWhenStarted() {
        let registration = Registration.fake
        let requested = UploadLog.Requested(startDate: Date(), symptoms: [.temperature])
        let persisting = PersistenceDouble(
            registration: registration,
            uploadLog: [
                UploadLog(event: .requested(requested)),
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
        let requested = UploadLog.Requested(startDate: Date(), symptoms: [.temperature])
        let persisting = PersistenceDouble(
            registration: registration,
            uploadLog: [
                UploadLog(event: .requested(requested)),
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
        let requested = UploadLog.Requested(startDate: Date(), symptoms: [.temperature])
        let persisting = PersistenceDouble(
            registration: registration,
            uploadLog: [
                UploadLog(event: .requested(requested)),
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
        let requested = UploadLog.Requested(startDate: Date(), symptoms: [.temperature])
        let persisting = PersistenceDouble(
            registration: registration,
            uploadLog: [
                UploadLog(event: .requested(requested)),
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

    // A request must have happened in the past since we have a completed event with
    // an attached error, but there is no log of the initial request because it was
    // created when we did not attach the start date to the request event. In this case,
    // we mark the upload as completed since we don't have the original start date.
    func testEnsureUploadingWithoutRequested() {
        let registration = Registration.fake
        let persisting = PersistenceDouble(
            registration: registration,
            uploadLog: [
                UploadLog(date: overAnHourAgo, event: .requested(nil)),
                UploadLog(date: overAnHourAgo, event: .completed(error: "oh no")),
            ]
        )
        let payload = IncomingBroadcastPayload.sample1
        let contactEvent = ContactEvent(broadcastPayload: payload)
        let contactEventRepository = ContactEventRepositoryDouble(contactEvents: [contactEvent])
        let session = SessionDouble()

        let uploader = ContactEventsUploader(
            persisting: persisting,
            contactEventRepository: contactEventRepository,
            makeSession: { _, _ in session }
        )

        try? uploader.ensureUploading()

        XCTAssertNotNil(contactEventRepository.removedThroughDate)
        XCTAssertEqual(persisting.uploadLog.map { $0.event }, [
            .requested(nil), .completed(error: "oh no"), .completed(error: nil)]
        )
        XCTAssertNil(session.uploadRequest)
    }


}

fileprivate extension ContactEventsUploader {
    
    convenience init(
        persisting: Persisting,
        contactEventRepository: ContactEventRepository,
        makeSession: (String, URLSessionTaskDelegate) -> Session
    ) {
        self.init(
            persisting: persisting,
            contactEventRepository: contactEventRepository,
            trustValidator: TrustValidatingDouble(),
            makeSession: makeSession
        )
    }
    
}
