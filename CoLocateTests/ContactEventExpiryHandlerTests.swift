//
//  ContactEventExpiryHandlerTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import XCTest
@testable import CoLocate

class ContactEventExpiryHandlerTests: XCTestCase {
    func testRemovesExpiredContactEventsOnSignificantTimeChange() {
        let notificationCenter = NotificationCenter()
        let contactEventRepository = ContactEventRepositoryDouble()
        let contactEventExpiryHandler = ContactEventExpiryHandler(notificationCenter: notificationCenter, contactEventRepository: contactEventRepository)
        withExtendedLifetime(contactEventExpiryHandler, {
            notificationCenter.post(name: UIApplication.significantTimeChangeNotification, object: nil)
            XCTAssertEqual(contactEventRepository.removeExpiredEntriesCallbackCount, 1)
        })
    }
}
