//
//  NotificationAcknowledgerTests.swift
//  SonarTests
//
//  Created by NHSX on 4/29/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class NotificationAcknowledgerTests: XCTestCase {

    var acker: NotificationAcknowledger!
    var persisting: PersistenceDouble!
    var session: SessionDouble!

    override func setUp() {
        persisting = PersistenceDouble()
        session = SessionDouble()
        acker = NotificationAcknowledger(persisting: persisting, session: session)
    }

    func testNoAcknowledgmentUrl() {
        let alreadyAcked = acker.ack(userInfo: [:])

        XCTAssertFalse(alreadyAcked)
        XCTAssertNil(session.requestSent)
    }

    func testSendingAcknowledgmentUrl() throws {
        let alreadyAcked = acker.ack(userInfo: ["acknowledgmentUrl": "https://example.com/ack"])

        XCTAssertFalse(alreadyAcked)

        let request = try XCTUnwrap(session.requestSent as? AcknowledgmentRequest)
        XCTAssertEqual(request.urlable, .url(URL(string: "https://example.com/ack")!))

        XCTAssertTrue(persisting.acknowledgmentUrls.contains(URL(string: "https://example.com/ack")!))
    }

    func testAlreadySentAcknowledgmentUrl() throws {
        persisting.acknowledgmentUrls = [URL(string: "https://example.com/ack")!]

        let alreadyAcked = acker.ack(userInfo: ["acknowledgmentUrl": "https://example.com/ack"])

        XCTAssertTrue(alreadyAcked)
        XCTAssertNotNil(session.requestSent)
    }

}
