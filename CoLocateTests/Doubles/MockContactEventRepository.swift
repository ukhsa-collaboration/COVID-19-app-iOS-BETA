//
//  MockContactEventRepository.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
@testable import CoLocate

class MockContactEventRepository: ContactEventRepository {

    var contactEvents: [ContactEvent] = []
    var hasReset: Bool = false

    init(contactEvents: [ContactEvent] = []) {
        self.contactEvents = contactEvents
    }

    func reset() {
        hasReset = true
    }

    func removeExpiredContactEvents(ttl: Double) {

    }
}
