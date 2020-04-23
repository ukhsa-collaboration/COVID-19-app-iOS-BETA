//
//  ContactEventUploaderTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class ContactEventUploaderTests: XCTestCase {

    func testUploadRequest() {
        let expectedBroadcastId = "opaque bytes that only the server can decrypt".data(using: .utf8)!
        let contactEvent = ContactEvent(encryptedRemoteContactId: expectedBroadcastId)
        let contactEventRepository = ContactEventRepositoryDouble()
        contactEventRepository.contactEvents = [contactEvent]
        let session = SessionDouble()

        let uploader = ContactEventUploader(
            contactEventRepository: contactEventRepository,
            session: session
        )

        let registration = Registration.fake
        try? uploader.upload(with: registration)

        guard
            let request = session.uploadRequest as? PatchContactEventsRequest,
            let fileURL = session.uploadFileURL
        else {
            XCTFail("Expected a PatchContactEventsRequest but got \(String(describing: session.requestSent))")
            return
        }

        XCTAssertEqual(request.path, "/api/residents/\(registration.id.uuidString)")

        var expectedData: Data?
        switch request.method {
        case .patch(let data):
            expectedData = data
        default:
            XCTFail("Expected a patch request but got \(request.method)")
        }

        let actualData = try? Data(contentsOf: fileURL)
//        let actualData = FileManager.default.contents(atPath: fileURL)
        XCTAssertEqual(actualData, expectedData)
    }

}
