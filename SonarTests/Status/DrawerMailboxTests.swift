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

    override func setUp() {
        super.setUp()

        persistence = PersistenceDouble()
        mailbox = DrawerMailbox(persistence: persistence)
    }

    func testNoMessages() {
        XCTAssertNil(mailbox.receive())
    }

    func testPushMessages() {
        mailbox.post(.unexposed)
        mailbox.post(.testResult(.negative))
        XCTAssertEqual(persistence.drawerMessages, [.unexposed, .testResult(.negative)])

        XCTAssertEqual(mailbox.receive(), .unexposed)
        XCTAssertEqual(mailbox.receive(), .testResult(.negative))
        XCTAssertNil(mailbox.receive())
    }

}

class DrawerMessageTests: XCTestCase {

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    func testRoundtrip() throws {
        let message = DrawerMessage.testResult(.positive)
        let encoded = try encoder.encode(message)
        let decoded = try decoder.decode(DrawerMessage.self, from: encoded)
        XCTAssertEqual(decoded, message)
    }

}
