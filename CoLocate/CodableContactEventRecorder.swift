//
//  CodableContactEventService.swift
//  CoLocate
//
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

class CodableContactEventRecorder: ContactEventRecorder {
    static let shared: CodableContactEventRecorder = CodableContactEventRecorder()
    private static let documentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let archiveURL = documentsDirectory.appendingPathComponent("ContactEvents")
    public private(set) var contactEvents: [ContactEvent] = []
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func record(_ contactEvent: ContactEvent) {
        contactEvents.append(contactEvent)

        do {
            let data = try encoder.encode(contactEvents)
            try data.write(to: Self.archiveURL, options: [.completeFileProtectionUntilFirstUserAuthentication])
        } catch {
            print("Error writing data to disk: \(error)")
        }
    }

    func reset() {
        do {
            try FileManager.default.removeItem(at: Self.archiveURL)
        } catch {
            assertionFailure("\(#file).\(#function) error removing file at '\(Self.archiveURL)': \(error)")
        }
        contactEvents = []
    }

    init() {
        contactEvents = loadEvents()
    }
    

    private func loadEvents() -> [ContactEvent] {
        do {
            let data = try Data(contentsOf: Self.archiveURL)
            return (try decoder.decode([ContactEvent].self, from: data) )
        }
        catch let error as CocoaError {
            if error.code == CocoaError.fileNoSuchFile {
                print("No such file: \(error)")
                let path = Self.archiveURL.path
                print("Creating file: \(path)")
                FileManager.default.createFile(atPath: path, contents: nil)
            }
        }
        catch {
            assertionFailure("Error reading file from disk: \(error)")
        }
        return []
    }
}
