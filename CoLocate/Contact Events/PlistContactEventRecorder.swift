//
//  ContactEventService.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Logging

class PlistContactEventRecorder: ContactEventRecorder {
    
    // MARK - New contact events
    
    static let shared: PlistContactEventRecorder = PlistContactEventRecorder()
    
    internal let fileURL: URL

    public private(set) var contactEvents: [ContactEvent] = []

    internal init() {
        if let dirUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            fileURL = dirUrl.appendingPathComponent("contactEvents.plist")
        } else {
            logger.critical("couldn't open file for writing contactEvents.plist")
            fatalError()
        }
        readContactEvents()
    }

    func record(_ contactEvent: ContactEvent) {
        contactEvents.append(contactEvent)
        writeContactEvents()
    }
    
    private func readContactEvents() {
        guard FileManager.default.isReadableFile(atPath: fileURL.path) else {
            contactEvents = []
            return
        }
        
        let decoder = PropertyListDecoder()
        do {
            let data = try Data(contentsOf: fileURL)
            contactEvents = try decoder.decode([ContactEvent].self, from: data)
        } catch {
            logger.critical("error reading contact events from disk: \(error)")
            fatalError()
        }
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
            logger.critical("error writing contact events to disk: \(error)")
            fatalError()
        }
    }
    
    func reset() {
        contactEvents = []
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch (let error as NSError) where error.code == NSFileNoSuchFileError {
            // ignore this, job already done
        } catch {
            logger.critical("error removing file at '\(fileURL)': \(error)")
            fatalError()
        }
    }
    
}

private let logger = Logger(label: "PlistContactEventsRecorder")
