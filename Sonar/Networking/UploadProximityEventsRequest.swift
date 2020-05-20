//
//  UploadProximityEventsRequest.swift
//  Sonar
//
//  Created by NHSX on 19.03.20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Logging

class UploadProximityEventsRequest: SecureRequest, Request {

    struct UploadableContactEvent: Codable {
        let encryptedRemoteContactId: Data
        let rssiValues: [Int8]
        let rssiIntervals: [Int32]
        let timestamp: Int32
        let duration: Int
        let txPowerInProtocol: Int8
        let txPowerAdvertised: Int8
        let hmacSignature: Data
        let transmissionTime: Int32
        let countryCode: Int16
    }
    
    struct Wrapper: Codable {
        let sonarId: UUID
        let symptoms: [String]
        let symptomsTimestamp: Date
        let contactEvents: [UploadableContactEvent]
    }

    typealias ResponseType = Void
    
    let method: HTTPMethod
    
    let urlable = Urlable.path("/api/proximity-events/upload")

    init(registration: Registration, symptoms: Symptoms, symptomsTimestamp: Date, contactEvents: [ContactEvent]) {
        let key = registration.secretKey
        let sonarId = registration.sonarId

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let uploadableEvents = contactEvents.compactMap { (event: ContactEvent) -> UploadableContactEvent? in
            guard let payload = event.broadcastPayload else {
                return nil
            }
            
            var rssiIntervals: [Int32] = []
            for (idx, timestamp) in event.rssiTimestamps.enumerated() {
                var interval: TimeInterval = 0.0
                if idx == 0 {
                    interval = timestamp.timeIntervalSince(event.timestamp)
                } else {
                    interval = timestamp.timeIntervalSince(event.rssiTimestamps[idx - 1])
                }
                rssiIntervals.append(Int32(interval))
            }
            
            return UploadableContactEvent(
                encryptedRemoteContactId: payload.cryptogram,
                rssiValues: event.rssiValues.map { Int8($0) },
                rssiIntervals: rssiIntervals,
                timestamp: Int32(event.timestamp.timeIntervalSince1970),
                duration: Int(event.duration),
                txPowerInProtocol: payload.txPower,
                txPowerAdvertised: event.txPower ?? Int8.min,
                hmacSignature: payload.hmac,
                transmissionTime: payload.transmissionTime,
                countryCode: payload.countryCode)
        }

        let requestBody = Wrapper(
            sonarId: sonarId,
            symptoms: symptoms.getSymptoms().map { $0.rawValue.uppercased() },
            symptomsTimestamp: symptomsTimestamp,
            contactEvents: uploadableEvents
        )
        let bodyAsData = try! encoder.encode(requestBody)
        
        logger.info("uploading contact events:\n \(String(data: bodyAsData, encoding: .utf8)!)")
        method = .patch(data: bodyAsData)

        super.init(key, bodyAsData, [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ])
    }
    
    func parse(_ data: Data) throws -> Void {
    }
 
    fileprivate let logger = Logger(label: "BTLE")
}
