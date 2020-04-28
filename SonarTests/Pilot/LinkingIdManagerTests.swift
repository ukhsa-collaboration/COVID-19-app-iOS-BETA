//
//  LinkingIdManagerTests.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class LinkingIdManagerTests: XCTestCase {

    func testFetchingAfterRegistration() {
        let notificationCenter = NotificationCenter()
        let persisting = PersistenceDouble(registration: Registration.fake)
        let session = SessionDouble()
        let _ = LinkingIdManager(
            notificationCenter: notificationCenter,
            persisting: persisting,
            session: session
        )

        notificationCenter.post(name: RegistrationCompletedNotification, object: nil)
        session.executeCompletion?(Result<LinkingId, Error>.success("linking-id"))

        XCTAssertEqual(persisting.linkingId, "linking-id")
    }

    func testFetchLinkingId() {
        let persisting = PersistenceDouble(registration: Registration.fake)
        let session = SessionDouble()
        let manager = LinkingIdManager(
            notificationCenter: NotificationCenter(),
            persisting: persisting,
            session: session
        )

        var fetchedLinkingId: LinkingId?
        manager.fetchLinkingId { fetchedLinkingId = $0 }
        session.executeCompletion?(Result<LinkingId, Error>.success("linking-id"))

        XCTAssertEqual(persisting.linkingId, "linking-id")
        XCTAssertEqual(fetchedLinkingId, "linking-id")
    }

    func testFetchLinkingIdFailure() {
        let persisting = PersistenceDouble(registration: Registration.fake)
        let session = SessionDouble()
        let manager = LinkingIdManager(
            notificationCenter: NotificationCenter(),
            persisting: persisting,
            session: session
        )

        var fetchedLinkingId: LinkingId?
        manager.fetchLinkingId { fetchedLinkingId = $0 }
        session.executeCompletion?(Result<LinkingId, Error>.failure(FakeError.fake))

        XCTAssertNil(persisting.linkingId)
        XCTAssertNil(fetchedLinkingId)
    }

}

class LinkingIdManagerDouble: LinkingIdManager {
    static func make(
        notificationCenter: NotificationCenter = NotificationCenter(),
        persisting: Persisting = PersistenceDouble(),
        session: Session = SessionDouble()
    ) -> LinkingIdManager {
        return LinkingIdManager(notificationCenter: notificationCenter, persisting: persisting, session: session)
    }

    var fetchCompletion: ((LinkingId?) -> Void)?
    override func fetchLinkingId(completion: @escaping (LinkingId?) -> Void = { _ in }) {
        fetchCompletion = completion
    }
}
