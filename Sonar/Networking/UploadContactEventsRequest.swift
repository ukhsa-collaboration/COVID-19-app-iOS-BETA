//
//  PatchContactEventsRequest.swift
//  Sonar
//
//  Created by NHSX on 19.03.20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import Logging

class UploadContactEventsRequest: SecureRequest, Request {

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
        let symptomsTimestamp: Date
        let contactEvents: [UploadableContactEvent]
    }

    typealias ResponseType = Void
    
    let method: HTTPMethod
    
    let urlable: Urlable

    init(registration: Registration, symptomsTimestamp: Date, contactEvents: [ContactEvent]) {
        let key = registration.secretKey
        let sonarId = registration.id
        urlable = .path("/api/residents/\(sonarId.uuidString)")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let uploadableEvents = contactEvents.compactMap { (event: ContactEvent) -> UploadableContactEvent? in
            guard let payload = event.broadcastPayload else {
                return nil
            }
            return UploadableContactEvent(
                encryptedRemoteContactId: payload.cryptogram,
                rssiValues: event.rssiValues.map { Int8($0) },
                rssiIntervals: event.rssiIntervals.map { Int32($0) },
                timestamp: Int32(event.timestamp.timeIntervalSince1970),
                duration: Int(event.duration),
                txPowerInProtocol: payload.txPower,
                txPowerAdvertised: event.txPower,
                hmacSignature: payload.hmac,
                transmissionTime: payload.transmissionTime,
                countryCode: payload.countryCode)
        }

        let requestBody = Wrapper(symptomsTimestamp: symptomsTimestamp, contactEvents: uploadableEvents)
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
