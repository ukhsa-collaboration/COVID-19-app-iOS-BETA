//
//  ContactEventExpiryHandlerTests.swift
//  SonarTests
//
//  Created on 17/04/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import XCTest
@testable import Sonar

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
    
    func testCanConvertDaysIntoSeconds() {
        let notificationCenter = NotificationCenter()
        let contactEventRepository = ContactEventRepositoryDouble()
        let contactEventExpiryHandler = ContactEventExpiryHandler(notificationCenter: notificationCenter, contactEventRepository: contactEventRepository)
        XCTAssertEqual(contactEventExpiryHandler.convertDaysIntoSeconds(days: 28), 2419200)
    }
}
