//
//  ContactEventPersisterDouble.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
@testable import CoLocate

class ContactEventPersisterDouble: ContactEventPersister {
    
    var items: [UUID: ContactEvent] = [:]
    
    func reset() {
        items = [:]
    }
    
    var updateCount = 0
    func update(items: [UUID: ContactEvent]) {
        updateCount = items.count
    }
}
