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

        var fetchedResult: LinkingIdResult?
        manager.fetchLinkingId { fetchedResult = $0 }
        session.executeCompletion?(Result<LinkingId, Error>.success("linking-id"))

        XCTAssertEqual(fetchedResult, .success("linking-id"))
    }

    func testNoRegistration() {
        let persisting = PersistenceDouble()
        let manager = LinkingIdManager(
            persisting: persisting,
            session: SessionDouble()
        )

        var fetchedResult: LinkingIdResult?
        manager.fetchLinkingId { fetchedResult = $0 }

        XCTAssertEqual(fetchedResult, .error("Please wait until your setup has completed to see the app reference code."))
    }

    func testFetchLinkingIdFailure() {
        let persisting = PersistenceDouble(registration: Registration.fake)
        let session = SessionDouble()
        let manager = LinkingIdManager(
            persisting: persisting,
            session: session
        )

        var fetchedResult: LinkingIdResult?
        manager.fetchLinkingId { fetchedResult = $0 }
        session.executeCompletion?(Result<LinkingId, Error>.failure(FakeError.fake))

        XCTAssertEqual(fetchedResult, .error("Please connect your phone to the internet to see the app reference code."))
    }

}
