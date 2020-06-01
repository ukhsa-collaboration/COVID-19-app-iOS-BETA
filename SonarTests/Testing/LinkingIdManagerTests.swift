//
//  LinkingIdManagerTests.swift
//  SonarTests
//
//  Created by NHSX on 4/25/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class LinkingIdManagerTests: XCTestCase {

    func testFetchLinkingId() {
        let persisting = PersistenceDouble(registration: Registration.fake)
        let session = SessionDouble()
        let manager = LinkingIdManager(
            persisting: persisting,
            session: session
        )

        var fetchedLinkingId: LinkingId?
        var fetchError: String?
        manager.fetchLinkingId {
            fetchedLinkingId = $0
            fetchError = $1
        }
        session.executeCompletion?(Result<LinkingId, Error>.success("linking-id"))

        XCTAssertEqual(fetchedLinkingId, "linking-id")
        XCTAssertNil(fetchError)
    }

    func testNoRegistration() {
        let persisting = PersistenceDouble()
        let manager = LinkingIdManager(
            persisting: persisting,
            session: SessionDouble()
        )

        var fetchedLinkingId: LinkingId?
        var fetchError: String?
        manager.fetchLinkingId {
            fetchedLinkingId = $0
            fetchError = $1
        }

        XCTAssertNil(fetchedLinkingId)
        XCTAssertEqual(fetchError, "Please wait until your setup has completed to see the app reference code.")
    }

    func testFetchLinkingIdFailure() {
        let persisting = PersistenceDouble(registration: Registration.fake)
        let session = SessionDouble()
        let manager = LinkingIdManager(
            persisting: persisting,
            session: session
        )

        var fetchedLinkingId: LinkingId?
        var fetchError: String?
        manager.fetchLinkingId {
            fetchedLinkingId = $0
            fetchError = $1
        }
        session.executeCompletion?(Result<LinkingId, Error>.failure(FakeError.fake))

        XCTAssertNil(fetchedLinkingId)
        XCTAssertEqual(fetchError, "Please connect your phone to the internet to see the app reference code.")
    }

}
