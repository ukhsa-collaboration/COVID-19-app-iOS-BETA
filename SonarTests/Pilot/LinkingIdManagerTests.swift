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

    func testNoRegistration() {
        let persisting = PersistenceDouble()
        let manager = LinkingIdManager(
            persisting: persisting,
            session: SessionDouble()
        )

        var fetchedLinkingId: LinkingId?
        manager.fetchLinkingId { fetchedLinkingId = $0 }

        XCTAssertNil(fetchedLinkingId)
    }

    func testFetchLinkingId() {
        let persisting = PersistenceDouble(registration: Registration.fake)
        let session = SessionDouble()
        let manager = LinkingIdManager(
            persisting: persisting,
            session: session
        )

        var fetchedLinkingId: LinkingId?
        manager.fetchLinkingId { fetchedLinkingId = $0 }
        session.executeCompletion?(Result<LinkingId, Error>.success("linking-id"))

        XCTAssertEqual(fetchedLinkingId, "linking-id")
    }

    func testFetchLinkingIdFailure() {
        let persisting = PersistenceDouble(registration: Registration.fake)
        let session = SessionDouble()
        let manager = LinkingIdManager(
            persisting: persisting,
            session: session
        )

        var fetchedLinkingId: LinkingId?
        manager.fetchLinkingId { fetchedLinkingId = $0 }
        session.executeCompletion?(Result<LinkingId, Error>.failure(FakeError.fake))

        XCTAssertNil(fetchedLinkingId)
    }

}

class LinkingIdManagerDouble: LinkingIdManager {
    static func make(
        notificationCenter: NotificationCenter = NotificationCenter(),
        persisting: Persisting = PersistenceDouble(),
        session: Session = SessionDouble()
    ) -> LinkingIdManager {
        return LinkingIdManager(persisting: persisting, session: session)
    }

    var fetchCompletion: ((LinkingId?) -> Void)?
    override func fetchLinkingId(completion: @escaping (LinkingId?) -> Void = { _ in }) {
        fetchCompletion = completion
    }
}
