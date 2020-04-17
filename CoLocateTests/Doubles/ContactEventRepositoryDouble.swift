//
//  ContactEventRepositoryDouble.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
@testable import CoLocate

class ContactEventRepositoryDouble: ContactEventRepository {
    
    var contactEvents: [ContactEvent] = []
    
    func reset() {
        contactEvents = []
    }
    
    var removeExpiredEntriesCallbackCount = 0
    func removeExpiredContactEvents() {
        removeExpiredEntriesCallbackCount += 1
    }
}
