//
//  LinkingIdManagerTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class LinkingIdManagerTests: XCTestCase {

    func testFetchingAfterRegistration() {
        let notificationCenter = NotificationCenter()
        let registration = Registration.fake
        let persisting = PersistenceDouble(registration: registration)
        let session = SessionDouble()
        let _ = LinkingIdManager(
            notificationCenter: notificationCenter,
            persisting: persisting,
            session: session
        )

        notificationCenter.post(name: RegistrationCompletedNotification, object: nil)

        guard
            let request = session.requestSent as? LinkingIdRequest
        else {
            XCTFail("Expected a LinkingIdRequest but got \(String(describing: session.requestSent))")
            return
        }

        XCTAssertEqual(request.path, "/api/residents/\(registration.id.uuidString)/linking-id")
        XCTAssertEqual(request.method, .put)

    }

}
