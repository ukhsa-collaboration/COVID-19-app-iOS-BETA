//
//  ContactEventService.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct ContactEvent: Equatable {
    let uuid: UUID
}

class ContactEventService {
    
//    let fileURL: URL

    public private(set) var contactEvents: [ContactEvent] = []

//    init() {
//        if let dirUrl = FileManager.default.urls(for: .userDirectory, in: .userDomainMask).first {
//            fileURL = dirUrl.appendingPathComponent("contactEvents.plist")
//
//        }
//        assertionFailure("\(#file).\(#function) couldn't open file for writing contactEvents.plist")
//    }
    
    private func loadContactEvents() {
        
    }
    
    func record(_ contactEvent: ContactEvent) { // probably also timestamp and distance
        print("\(#file).\(#function) recording contactEvent with UUID: \(contactEvent.uuid)")
        
        contactEvents.append(contactEvent)
    }
    
}
