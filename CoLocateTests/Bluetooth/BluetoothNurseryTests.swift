//
//  BluetoothNurseryTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class BluetoothNurseryTests: TestCase {
    func testCreatesStateObserverWhenListenerCreated() {
        let nursery = ConcreteBluetoothNursery(persistence: PersistenceDouble(), userNotificationCenter: UserNotificationCenterDouble(), notificationCenter: NotificationCenter())
        XCTAssertNil(nursery.stateObserver)
        
        nursery.createListener()
        XCTAssertNotNil(nursery.stateObserver)
    }
}
