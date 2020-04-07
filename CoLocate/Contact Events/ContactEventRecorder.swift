//
//  ContactEventRecorder.swift
//  CoLocate
//
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct ContactEvent: Equatable, Codable {

    let sonarId: UUID
    var timestamp: Date = Date()
    var rssiValues: [Int] = []
    var duration: TimeInterval = 0

    mutating func disconnect() {
        duration = Date().timeIntervalSince(timestamp)
    }

}

protocol ContactEventRecorder {
    
    var contactEvents: [ContactEvent] { get }
    
    func record(_ contactEvent: ContactEvent)
    
    func reset()

}
