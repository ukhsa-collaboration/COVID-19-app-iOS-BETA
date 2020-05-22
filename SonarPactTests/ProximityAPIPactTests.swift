//
//  ProximityAPIPactTests.swift
//  SonarPactTests
//
//  Created by NHSX on 20/5/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
import PactConsumerSwift
import CommonCrypto

@testable import Sonar

class ProximityAPIPactTests: XCTestCase {
    
    var proximityAPIMockService: MockService!
    
    override func setUp() {
        super.setUp()
        
        proximityAPIMockService = MockService(
            provider: "Proximity API",
            consumer: "iOS App",
            pactVerificationService: PactMockServiceHelper.createVerificationService()
        )
    }
    
    override class func tearDown() {
        PactMockServiceHelper.clearSession()
    }
    
    #if targetEnvironment(simulator)
    func testUploadProximityEventsPact() {
        let registration = Registration(
            sonarId: ProviderKnownDetails.userId,
            secretKey: ProviderKnownDetails.secretKey,
            broadcastRotationKey: ProviderKnownDetails.broadcastKey
        )
        
        let request = UploadProximityEventsRequest(
            registration: registration,
            symptoms: Symptoms(arrayLiteral: Symptom.cough),
            symptomsTimestamp: ProviderKnownDetails.date,
            contactEvents: (1...3).map({ _ in ContactEvent.createRandomAtAbout(date: ProviderKnownDetails.date)
            })
        )
        
        let body = try! JSONSerialization.jsonObject(with: request.urlRequest().httpBody!, options: [])
        let signature = HMACHelper.createSignatureForBodyWithNewlinesAndSpaces(ProviderKnownDetails.secretKey, body, ProviderKnownDetails.timestamp)
        
        proximityAPIMockService
            .given("time is known and the user uploading is registered")
            .uponReceiving("a proximity data submission")
            .withRequest(
                method: .PATCH,
                path: "/api/proximity-events/upload",
                headers: [
                    "Accept": "application/json",
                    "Content-Type": "application/json",
                    "Sonar-Request-Timestamp": Matcher.term(
                        matcher: "[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z",
                        generate: ProviderKnownDetails.timestamp
                    ),
                    "Sonar-Message-Signature": Matcher.somethingLike(signature)
                ],
                body: body
        ).willRespondWith(status: 204)
        
        proximityAPIMockService.run(timeout: 60) { (testComplete) -> Void in
            let urlSession: Session = URLSession(configuration: .default)
            
            urlSession.execute(request, queue: .main) { result in
                try! result.get()
                testComplete()
            }
        }
    }
    
    func testGetLinkingIdPact() {
        let request = LinkingIdRequest(
            registration: Registration(
                sonarId: ProviderKnownDetails.userId,
                secretKey: ProviderKnownDetails.secretKey,
                broadcastRotationKey: ProviderKnownDetails.broadcastKey
            )
        )
        
        let body = try! JSONSerialization.jsonObject(with: request.urlRequest().httpBody!, options: [])
        let signature = HMACHelper.createSignatureForBodyWithNewlinesAndSpaces(ProviderKnownDetails.secretKey, body, ProviderKnownDetails.timestamp)
        
        proximityAPIMockService
            .given("time is known and the user requesting the id is registered")
            .uponReceiving("a reference code request")
            .withRequest(
                method: .PUT,
                path: "/api/app-instances/linking-id",
                headers: [
                    "Accept": "application/json",
                    "Content-Type": "application/json",
                    "Sonar-Request-Timestamp": Matcher.term(
                        matcher: "[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z",
                        generate: ProviderKnownDetails.timestamp
                    ),
                    "Sonar-Message-Signature": Matcher.somethingLike(signature)
                ],
                body: body
        ).willRespondWith(status: 200, body: [
            "linkingId": Matcher.term(
                matcher: "[0-9-abcdefghjkmnpqrstvwxyz]{4,20}",
                generate: "abcd-efdj")
        ])
        
        proximityAPIMockService.run(timeout: 60) { (testComplete) -> Void in
            let urlSession: Session = URLSession(configuration: .default)
            
            urlSession.execute(request, queue: .main) { result in
                let linkingId = try! result.get()
                XCTAssertEqual(linkingId, "abcd-efdj")
                testComplete()
            }
        }
    }
    #endif
}

extension ContactEvent {
    static func createRandomAtAbout(date: Date) -> ContactEvent {
        let numRssi = Int8.random(in: 3...8)
        let anHour = (60*60)
        let twoDays = (48*anHour)
        
        return ContactEvent(
            broadcastPayload: IncomingBroadcastPayload.random,
            txPower: Int8.random(in: 12...64),
            timestamp: date.addingTimeInterval(TimeInterval(Int.random(in: -twoDays...twoDays))),
            rssiValues: (1...numRssi).map({ _ in Int8.random(in: 8...64) }),
            rssiTimestamps: (1...numRssi).map({ _ in date.addingTimeInterval(TimeInterval(Int.random(in: -twoDays...twoDays))) }),
            duration: TimeInterval(Int.random(in: 3...(3*60)))
        )
    }
}

extension IncomingBroadcastPayload {
    static var random: IncomingBroadcastPayload {
        let replaceWith = UInt16.random(in: 1...3)
        var data = Data(count: BroadcastPayload.length)
        data.replaceSubrange(0..<2, with: replaceWith.networkByteOrderData)
        data.replaceSubrange(2..<4, with: replaceWith.networkByteOrderData)
        return IncomingBroadcastPayload(data: data)
    }
}
