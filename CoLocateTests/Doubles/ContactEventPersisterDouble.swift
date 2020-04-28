//
//  ContactEventPersisterDouble.swift
//  SonarTests
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
}
