//
//  ContactEventService.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct ContactEvent: Equatable, Codable {
    let uuid: UUID
}

class ContactEventService {
    
    let fileURL: URL

    public private(set) var contactEvents: [ContactEvent] = []

    init() {
        if let dirUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            fileURL = dirUrl.appendingPathComponent("contactEvents.plist")
            
        } else {
            fileURL = URL(string: "")!
            assertionFailure("\(#file).\(#function) couldn't open file for writing contactEvents.plist")
        }
    }
    
    private func loadContactEvents() {
        
    }
    
    func record(_ contactEvent: ContactEvent) { // probably also timestamp and distance
        print("\(#file).\(#function) recording contactEvent with UUID: \(contactEvent.uuid)")
        
        contactEvents.append(contactEvent)
        writeContactEvents()
    }
    
    private func writeContactEvents() {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        do {
            // TODO: These writing options mean if we reboot and are woken from background by a
            // BTLE event before the user unlocks their phone, we won't be able to record any data.
            // Can this happen in practice? Does it matter?
            let data = try encoder.encode(contactEvents)
            try data.write(to: fileURL, options: [.completeFileProtectionUntilFirstUserAuthentication])
        } catch {
            print("\(#file).\(#function) error writing contact events to disk: \(error)")
        }
//        FileManager.default.createFile(atPath: fileURL.path, contents: data, attributes: [.protectionKey: URLFileProtection.completeUntilFirstUserAuthentication])
    }
    
    func reset() {
        contactEvents = []
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            print("\(#file).\(#function) error removing file at '\(fileURL)': \(error)")
        }
    }
    
}
