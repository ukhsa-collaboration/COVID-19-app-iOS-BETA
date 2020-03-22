//
//  ContactEventRecorder.swift
//  CoLocate
//
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct ContactEvent: Equatable, Codable {
    let uuid: UUID
    let timestamp: String
    let rssi: Int
}

protocol ContactEventRecorder {
    func record(_ contactEvent: ContactEvent)
    func reset()
    var contactEvents: [ContactEvent] { get }
}
