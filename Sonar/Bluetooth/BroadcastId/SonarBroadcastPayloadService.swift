//
//  ConcreteBroadcastIdGenerator.swift
//  Sonar
//
//  Created by NHSX on 10/04/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Logging

protocol BroadcastPayloadService {
    func broadcastPayload(date: Date) -> BroadcastPayload?
}

extension BroadcastPayloadService {
    func broadcastPayload(date: Date = Date()) -> BroadcastPayload? {
        return broadcastPayload(date: date)
    }
}

class SonarBroadcastPayloadService: BroadcastPayloadService {

    let storage: BroadcastRotationKeyStorage
    let persistence: Persisting
    let encrypter: BroadcastIdEncrypter

    init(storage: BroadcastRotationKeyStorage, persistence: Persisting, encrypter: BroadcastIdEncrypter) {
        self.storage = storage
        self.persistence = persistence
        self.encrypter = encrypter
    }

    func broadcastPayload(date: Date) -> BroadcastPayload? {
        guard let hmacKey = persistence.registration?.secretKey, let secKey = persistence.registration?.broadcastRotationKey, let sonarId = persistence.registration?.sonarId else {
            return nil
        }

        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "UTC")!
        if let (broadcastId, broadcastIdDate) = storage.readBroadcastId(), calendar.isDate(broadcastIdDate, inSameDayAs: date) {
            return BroadcastPayload(cryptogram: broadcastId, hmacKey: hmacKey)
        }
        
        let midnightUTC = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: date)!)

        let broadcastId = encrypter.broadcastId(secKey: secKey, sonarId: sonarId, from: date, until: midnightUTC)
        storage.save(broadcastId: broadcastId, date: date)
        return BroadcastPayload(cryptogram: broadcastId, hmacKey: hmacKey)
    }

}

fileprivate let logger = Logger(label: "BTLE")
