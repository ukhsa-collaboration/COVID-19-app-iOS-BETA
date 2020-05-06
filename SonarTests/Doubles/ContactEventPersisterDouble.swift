//
//  ContactEventPersisterDouble.swift
//  SonarTests
//
//  Created by NHSX on 4/13/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
@testable import Sonar

class ContactEventPersisterDouble: ContactEventPersister {
    
    public private(set) var items: [UUID: ContactEvent] = [:]
    
    func update(item: ContactEvent, key: UUID) {
        items[key] = item
    }
    
    func replaceAll(with newItems: [UUID : ContactEvent]) {
        items = newItems
    }

    
    func reset() {
        items = [:]
    }
}
