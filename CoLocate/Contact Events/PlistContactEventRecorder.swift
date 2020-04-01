//
//  ContactEventService.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

class PlistContactEventRecorder: ContactEventRecorder {
    
    // MARK - New contact events
    
    func record(_ contactEvent: ContactEvent) {
    }
    
    var contactEvents: [ContactEvent] = []
    
    static let shared: PlistContactEventRecorder = PlistContactEventRecorder()
    
    internal let fileURL: URL

    public private(set) var oldContactEvents: [OldContactEvent] = []

    internal init() {
        if let dirUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            fileURL = dirUrl.appendingPathComponent("contactEvents.plist")
        } else {
            preconditionFailure("\(#file).\(#function) couldn't open file for writing contactEvents.plist")
        }
        readContactEvents()
    }

    func record(_ contactEvent: OldContactEvent) {
        oldContactEvents.append(contactEvent)
        writeContactEvents()
    }
    
    private func readContactEvents() {
        guard FileManager.default.isReadableFile(atPath: fileURL.path) else {
            oldContactEvents = []
            return
        }
        
        let decoder = PropertyListDecoder()
        do {
            let data = try Data(contentsOf: fileURL)
            oldContactEvents = try decoder.decode([OldContactEvent].self, from: data)
        } catch {
            assertionFailure("\(#file).\(#function) error reading contact events from disk: \(error)")
        }
    }
    
    private func writeContactEvents() {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        do {
            // TODO: These writing options mean if we reboot and are woken from background by a
            // BTLE event before the user unlocks their phone, we won't be able to record any data.
            // Can this happen in practice? Does it matter?
            let data = try encoder.encode(oldContactEvents)
            try data.write(to: fileURL, options: [.completeFileProtectionUntilFirstUserAuthentication])
        } catch {
            assertionFailure("\(#file).\(#function) error writing contact events to disk: \(error)")
        }
    }
    
    func reset() {
        oldContactEvents = []
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch (let error as NSError) where error.code == NSFileNoSuchFileError {
            // ignore this, job already done
        } catch {
            assertionFailure("\(#file).\(#function) error removing file at '\(fileURL)': \(error)")
        }
    }
    
}
