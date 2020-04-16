//
//  PlistPersister.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Logging

class PlistPersister<K: Hashable & Codable, V: Codable> {
    
    var items: [K: V] = [:] {
        didSet {
            writeItems()
        }
    }
    
    internal let fileURL: URL
    
    private let encoder: PropertyListEncoder

    internal init(fileName: String) {
        if let dirUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            fileURL = dirUrl.appendingPathComponent(fileName + ".plist")
        } else {
            logger.critical("couldn't open file for writing \(fileName).plist")
            fatalError()
        }
        encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        readItems()
    }
    
    func clear() {
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch (let error as NSError) where error.code == NSFileNoSuchFileError {
            // ignore this, job already done
        } catch {
            logger.critical("error removing file at '\(fileURL)': \(error)")
            fatalError()
        }
    }
    
    func reset() {
        items = [:]
        clear()
    }
    
    func update(items: [K: V]) {
        self.items = items
    }

    private func readItems() {
        guard FileManager.default.isReadableFile(atPath: fileURL.path) else {
            items = [:]
            return
        }
        
        let decoder = PropertyListDecoder()
        do {
            let data = try Data(contentsOf: fileURL)
            items = try decoder.decode([K: V].self, from: data)
        } catch {
            logger.critical("error reading items from plist, did the format change? \(error)")
            items = [:]
//            fatalError()
        }
    }

    private func writeItems() {
        do {
            // TODO: These writing options mean if we reboot and are woken from background by a
            // BTLE event before the user unlocks their phone, we won't be able to record any data.
            // Can this happen in practice? Does it matter?
            let data = try encoder.encode(items)
            try data.write(to: fileURL, options: [.completeFileProtectionUntilFirstUserAuthentication])
        } catch {
            logger.critical("error writing items to disk: \(error)")
            fatalError()
        }
    }

}

private let logger = Logger(label: "PlistPersister")
