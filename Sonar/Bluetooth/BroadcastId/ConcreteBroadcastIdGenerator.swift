//
//  ConcreteBroadcastIdGenerator.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Logging

protocol BroadcastIdGenerator {
    func broadcastIdentifier(date: Date) -> Data?
}

extension BroadcastIdGenerator {
    func broadcastIdentifier(date: Date = Date()) -> Data? {
        return broadcastIdentifier(date: date)
    }
}

class ConcreteBroadcastIdGenerator: BroadcastIdGenerator {

    let storage: BroadcastRotationKeyStorage
    var provider: BroadcastIdEncrypterProvider

    init(storage: BroadcastRotationKeyStorage, provider: BroadcastIdEncrypterProvider) {
        self.storage = storage
        self.provider = provider
    }

    func broadcastIdentifier(date: Date) -> Data? {
        if let (broadcastId, broadcastIdDate) = storage.readBroadcastId(), Calendar.current.isDateInToday(broadcastIdDate) {
            return broadcastId
        }
        
        let midnight = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: date)!)
        if let broadcastId = provider.getEncrypter()?.broadcastId(from: date, until: midnight) {
            storage.save(broadcastId: broadcastId, date: date)
            return broadcastId
        } else {
            return nil
        }
    }

}

fileprivate let logger = Logger(label: "BTLE")
