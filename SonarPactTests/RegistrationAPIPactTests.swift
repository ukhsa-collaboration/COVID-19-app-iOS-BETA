//
//  RegistrationAPIPactTests.swift
//  RegistrationAPIPactTests
//
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
import PactConsumerSwift
@testable import Sonar

class RegistrationAPIPactTests: XCTestCase {
    
    var registrationAPIMockService: MockService!
    
    override func setUp() {
        super.setUp()
        
        registrationAPIMockService = MockService(
            provider: "Registration API",
            consumer: "iOS App",
            pactVerificationService: PactVerificationService(
                url: "https://localhost",
                port: 1234
            )
        )
    }
    
    
    #if targetEnvironment(simulator)
    func testRegistrationRequestPact() {
        registrationAPIMockService
            .given("no existing registration")
            .uponReceiving("a registration request")
            .withRequest(method: .POST, path: "/api/devices/registrations", body: [
                "pushToken": Matcher.term(matcher: ".{15,2048}", generate: "a-valid-token-with-min-length-15")
            ])
            .willRespondWith(status: 204)
        
        registrationAPIMockService.run(timeout: 60) { (testComplete) -> Void in
            let request = RequestFactory.registrationRequest(pushToken: "a-valid-token-with-min-length-15")
            
            let urlSession: Session = URLSession(configuration: .default)
            
            urlSession.execute(request, queue: .main) { result in
                try! result.get()
                testComplete()
            }
        }
    }
    
    func testRegistrationConfirmationPact() {
        let clientSymmetricKey = "OuO0LzMf+b7Cw4IYAFRH+5QLCUwGTTX+X9E8bRdqAD4="
        let serverPublicKey = "MDYwEAYHKoZIzj0CAQYFK4EEABwDIgAEWpdG8K775X/T7DSqq06ttLU1UwiE+RxMJNK6ErZ7uRM="
        let registrationId = UUID().uuidString
        
        registrationAPIMockService
            .given("a successful registration start request")
            .uponReceiving("a device confirmation request")
            .withRequest(method: .POST, path: "/api/devices", body: [
                "activationCode": Matcher.uuid(),
                "pushToken": Matcher.term(matcher: ".{15,240}", generate: "a-valid-token-with-min-length-15"),
                "deviceModel": Matcher.term(matcher: ".{1,30}", generate: "model12"),
                "deviceOSVersion": Matcher.term(matcher: ".{1,30}", generate: "iOS 13.4"),
                "postalCode": Matcher.term(matcher: "^[A-Z]{1,2}[0-9R][0-9A-Z]?", generate: "EC1V")
            ])
            .willRespondWith(status: 200, headers: [String: Any](), body: [
                "secretKey": Matcher.term(matcher: ".+", generate: clientSymmetricKey),
                "publicKey": Matcher.term(matcher: ".+", generate: serverPublicKey),
                "id":  Matcher.uuid(registrationId)
            ])
        
        registrationAPIMockService.run(timeout: 60) { (testComplete) -> Void in
            let request = RequestFactory.confirmRegistrationRequest(activationCode: UUID().uuidString, pushToken: "a-valid-token-with-min-length-15", postalCode: "SW11")
            
            let urlSession: Session = URLSession(configuration: .default)
            
            urlSession.execute(request, queue: .main) { result in
                let response = try! result.get()
                XCTAssertEqual(response.secretKey, HMACKey(data: Data(base64Encoded: clientSymmetricKey)!))
                XCTAssertEqual(response.serverPublicKey, Data(base64Encoded: serverPublicKey))
                XCTAssertEqual(response.sonarId, UUID(uuidString: registrationId))
                
                testComplete()
            }
        }
    }
    
    func testPushNotificationTokenUpdatePact() {
        let token = UUID().uuidString
        let request = UpdatePushNotificationTokenRequest(           registration: Registration(
            sonarId: ProviderKnownDetails.userId,
            secretKey: ProviderKnownDetails.secretKey,
            broadcastRotationKey: ProviderKnownDetails.broadcastKey
        ), token: token)
        let body = try! JSONSerialization.jsonObject(with: request.urlRequest().httpBody!, options: [])
        let signature = HMACHelper.createSignatureForBodyWithNewlinesAndSpaces(ProviderKnownDetails.secretKey, body, ProviderKnownDetails.timestamp)
        
        registrationAPIMockService
            .given("time is known and the user updating the token is registered")
            .uponReceiving("an updated push token")
            .withRequest(method: .PUT, path: "/api/registration/push-notification-token",
                         headers: [
                            "Content-Type": "application/json",
                            "Sonar-Request-Timestamp": Matcher.term(
                                matcher: "[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z",
                                generate: ProviderKnownDetails.timestamp
                            ),
                            "Sonar-Message-Signature": Matcher.somethingLike(signature)
                         ],
                         body: [
                            "sonarId": Matcher.uuid(ProviderKnownDetails.userId.uuidString),
                            "pushNotificationToken": Matcher.term(matcher: ".{15,240}", generate: token)
                         ])
            .willRespondWith(status: 204)
        
        registrationAPIMockService.run(timeout: 60) { (testComplete) -> Void in
            let urlSession: Session = URLSession(configuration: .default)
            
            urlSession.execute(request, queue: .main) { result in
                try! result.get()
                testComplete()
            }
        }
    }
    #endif
}
