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
    func testInvokesRemoveExpiredContactEventsOnInit() {
        let notificationCenter = NotificationCenter()
        let contactEventRepository = ContactEventRepositoryDouble()
        let contactEventExpiryHandler = ContactEventExpiryHandler(notificationCenter: notificationCenter, contactEventRepository: contactEventRepository)
        withExtendedLifetime(contactEventExpiryHandler, {
            XCTAssertEqual(contactEventRepository.removeExpiredEntriesCallbackCount, 1)
        })
    }
    
    func testRemovesExpiredContactEventsOnSignificantTimeChange() {
        let notificationCenter = NotificationCenter()
        let contactEventRepository = ContactEventRepositoryDouble()
        let contactEventExpiryHandler = ContactEventExpiryHandler(notificationCenter: notificationCenter, contactEventRepository: contactEventRepository)
        withExtendedLifetime(contactEventExpiryHandler, {
            contactEventRepository.removeExpiredEntriesCallbackCount = 0
            notificationCenter.post(name: UIApplication.significantTimeChangeNotification, object: nil)
            XCTAssertEqual(contactEventRepository.removeExpiredEntriesCallbackCount, 1)
        })
    }
}
