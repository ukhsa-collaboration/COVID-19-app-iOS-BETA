//
//  ContactEventService.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct ContactEvent {
    let uuid: UUID
}

class ContactEventService {
    
    func record(_ contactEvent: ContactEvent) { // probably also timestamp and distance
        print("\(#file).\(#function) recorded contactEvent with UUID: \(contactEvent.uuid)")
    }
    
}
