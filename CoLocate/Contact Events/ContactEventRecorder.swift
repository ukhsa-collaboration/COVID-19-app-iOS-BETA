//
//  ContactEventRecorder.swift
//  CoLocate
//
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct ContactEvent: Equatable, Codable {
    let sonarId: UUID
    let timestamp: Date
    let rssiValues: [Int]
    let duration: TimeInterval
}

protocol ContactEventRecorder {
    
    var contactEvents: [ContactEvent] { get }
    
    func record(_ contactEvent: ContactEvent)
    
    func reset()

}
