//
//  BluetoothNurseryTests.swift
//  SonarTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class BluetoothNurseryTests: TestCase {
    func testStartsBroadcastingOnceRegistrationIsPersisted() {
        let persistence = PersistenceDouble()
        let nursery = ConcreteBluetoothNursery(persistence: persistence,
                                               userNotificationCenter: UserNotificationCenterDouble(),
                                               notificationCenter: NotificationCenter())
        
        XCTAssertNil(nursery.broadcastIdGenerator.sonarId)
        
        let registration = Registration.fake
        persistence.delegate?.persistence(persistence, didUpdateRegistration: registration)

        XCTAssertEqual(nursery.broadcastIdGenerator.sonarId, registration.id)
    }

    func test_whenRegistrationIsSaved_theBroadcasterIsInformedToUpdate() throws {
        throw XCTSkip("This test can't be written until the nursery's functional behavior is decoupled from the creation of objects.")
    }

    func test_isHealthy_afterStarted() throws {
        throw XCTSkip("This test fails because the broadcaster and listener aren't immediately healthy. Decouple behavior from creation of objects")

        let nursery = ConcreteBluetoothNursery(persistence: PersistenceDouble(),
                                               userNotificationCenter: UserNotificationCenterDouble(),
                                               notificationCenter: NotificationCenter())

        XCTAssertFalse(nursery.isHealthy)

        nursery.startBluetooth(registration: nil)

        XCTAssertTrue(nursery.isHealthy)
    }
}
