//
//  ConcreteBroadcastIdGenerator.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Logging

protocol BroadcastPayloadGenerator {
    func broadcastPayload(date: Date) -> BroadcastPayload?
}

extension BroadcastPayloadGenerator {
    func broadcastPayload(date: Date = Date()) -> BroadcastPayload? {
        return broadcastPayload(date: date)
    }
}

class SonarBroadcastPayloadGenerator: BroadcastPayloadGenerator {

    let storage: BroadcastRotationKeyStorage
    let persistence: Persisting
    let provider: BroadcastIdEncrypterProvider

    init(storage: BroadcastRotationKeyStorage, persistence: Persisting, provider: BroadcastIdEncrypterProvider) {
        self.storage = storage
        self.persistence = persistence
        self.provider = provider
    }

    func broadcastPayload(date: Date) -> BroadcastPayload? {
        // TODO: Using the UTC calendar here to try and ensure isDateInToday() uses "today UTC" is not tested, but should be—need minute to midnight, midnight, minute past midnight tests
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "UTC")!
        if let (broadcastId, broadcastIdDate) = storage.readBroadcastId(), calendar.isDateInToday(broadcastIdDate), let hmacKey = persistence.registration?.secretKey {
            return BroadcastPayload(cryptogram: broadcastId, hmacKey: hmacKey)
        }
        
        let midnightUTC = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: date)!)

        if let broadcastId = provider.getEncrypter()?.broadcastId(from: date, until: midnightUTC) {
            storage.save(broadcastId: broadcastId, date: date)
            // TODO: This force unwrap is terrible, but it's safe as we can't get here until getEncrypter()
            // returns a value, which it will when the registration is filled out
            return BroadcastPayload(cryptogram: broadcastId, hmacKey: persistence.registration!.secretKey)
        } else {
            return nil
        }
    }

}

fileprivate let logger = Logger(label: "BTLE")
