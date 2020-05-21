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
        let registration = Registration.fake
        let token = UUID().uuidString
        
        registrationAPIMockService
            .given("an existing registration")
            .uponReceiving("an updated push token")
            .withRequest(method: .PUT, path: "/api/registration/push-notification-token", body: [
                "sonarId": Matcher.uuid(registration.sonarId.uuidString),
                "pushNotificationToken": Matcher.term(matcher: ".{15,240}", generate: token)
            ])
            .willRespondWith(status: 204, headers: [String: Any](), body: [])

        registrationAPIMockService.run(timeout: 60) { (testComplete) -> Void in
            let request = UpdatePushNotificationTokenRequest(registration: registration, token: token)

            let urlSession: Session = URLSession(configuration: .default)

            urlSession.execute(request, queue: .main) { result in
                testComplete()
            }
        }
    }
    #endif
}

private extension Registration {
    static var fake: Self {
        Registration(sonarId: UUID(), secretKey: SecKey.sampleHMACKey, broadcastRotationKey: SecKey.sampleEllipticCurveKey)
    }
}

private extension SecKey {
    static var sampleEllipticCurveKey: SecKey {
        let data = Data.init(base64Encoded: "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEu1f68MqDXbKeTqZMTHsOGToO4rKnPClXe/kE+oWqlaWZQv4J1E98cUNdpzF9JIFRPMCNdGOvTr4UB+BhQv9GWg==")!
        return try! BroadcastRotationKeyConverter().fromData(data)
    }
    
    static var knownGoodECPublicKey: SecKey {
        let data = Data(base64Encoded: "BDSTjw7/yauS6iyMZ9p5yl6i0n3A7qxYI/3v+6RsHt8o+UrFCyULX3fKZuA6ve+lH1CAItezr+Tk2lKsMcCbHMI=")!

        let keyDict: [NSObject: NSObject] = [
           kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
           kSecAttrKeyClass: kSecAttrKeyClassPublic,
           kSecAttrKeySizeInBits: NSNumber(value: 256),
           kSecReturnPersistentRef: true as NSObject
        ]

        return SecKeyCreateWithData(data as CFData, keyDict as CFDictionary, nil)!
    }
    
    static var sampleHMACKey: HMACKey = HMACKey(data: Data(base64Encoded: "LWbqBBxfV5vob3ApsPhgOI8aiFcKYP8jLQ2fKb8Y1C0=")!)

}
