//
//  ContactEventRecorder.swift
//  CoLocate
//
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

protocol ContactEventRecorder {
    func record(_ contactEvent: ContactEvent)
    func reset()
    var contactEvents: [ContactEvent] { get }
}

extension PlistContactEventService: ContactEventRecorder {}
