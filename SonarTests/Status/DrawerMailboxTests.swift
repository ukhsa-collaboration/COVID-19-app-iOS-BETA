//
//  DrawerMailboxTests.swift
//  SonarTests
//
//  Created by NHSX on 5/27/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class DrawerMailboxTests: XCTestCase {

    var mailbox: DrawerMailbox!
    var persistence: PersistenceDouble!
    var notificationCenter: NotificationCenter!

    override func setUp() {
        super.setUp()

        persistence = PersistenceDouble()
        notificationCenter = NotificationCenter()
        mailbox = DrawerMailbox(persistence: persistence, notificationCenter: notificationCenter)
    }

    func testNoMessages() {
        XCTAssertNil(mailbox.receive())
    }

    func testPushMessages() {
        mailbox.post(.unexposed)
        mailbox.post(.negativeTestResult)
        XCTAssertEqual(persistence.drawerMessages, [.unexposed, .negativeTestResult])

        XCTAssertEqual(mailbox.receive(), .unexposed)
        XCTAssertEqual(mailbox.receive(), .negativeTestResult)
        XCTAssertNil(mailbox.receive())
    }

    func testNotifyOnPosts() {
        var notificationPosted = false
        notificationCenter.addObserver(
            forName: DrawerMessage.DrawerMessagePosted,
            object: nil,
            queue: nil
        ) { _ in
            notificationPosted = true
        }

        mailbox.post(.unexposed)

        XCTAssertTrue(notificationPosted)
    }

    func testOnlyOneCheckinAtATime() {
        mailbox.post(.checkin)
        mailbox.post(.checkin)
        XCTAssertEqual(persistence.drawerMessages, [.checkin])

        XCTAssertEqual(mailbox.receive(), .checkin)
        XCTAssertNil(mailbox.receive())
    }

}

class DrawerMessageTests: XCTestCase {

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    func testRoundtripUnexposed() throws {
        let message = DrawerMessage.unexposed
        let encoded = try encoder.encode(message)
        let decoded = try decoder.decode(DrawerMessage.self, from: encoded)
        XCTAssertEqual(decoded, message)
    }

    func testRoundtripSymptomsButNotSymptomatic() throws {
        let message = DrawerMessage.symptomsButNotSymptomatic
        let encoded = try encoder.encode(message)
        let decoded = try decoder.decode(DrawerMessage.self, from: encoded)
        XCTAssertEqual(decoded, message)
    }

    func testRoundtripPositive() throws {
        let message = DrawerMessage.positiveTestResult
        let encoded = try encoder.encode(message)
        let decoded = try decoder.decode(DrawerMessage.self, from: encoded)
        XCTAssertEqual(decoded, message)
    }

    func testRoundtripNegativeWithoutSymptoms() throws {
        let message = DrawerMessage.negativeTestResult
        let encoded = try encoder.encode(message)
        let decoded = try decoder.decode(DrawerMessage.self, from: encoded)
        XCTAssertEqual(decoded, message)
    }

    func testRoundtripUnclear() throws {
        let message = DrawerMessage.unclearTestResult
        let encoded = try encoder.encode(message)
        let decoded = try decoder.decode(DrawerMessage.self, from: encoded)
        XCTAssertEqual(decoded, message)
    }

}
