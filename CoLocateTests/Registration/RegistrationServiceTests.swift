//
//  RegistrationServiceTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class RegistrationServiceTests: TestCase {

    let id = UUID()
    let secretKey = "a secret key".data(using: .utf8)!

    func testRegistration_withPreExistingPushToken() throws {
        let session = SessionDouble()
        let pushNotificationManager = PushNotificationManagerDouble()
        let notificationCenter = NotificationCenter()
        let observer = NotificationObserverDouble(notificationCenter: notificationCenter, notificationName: RegistrationCompleteNotification)
        let registrationService = ConcreteRegistrationService(session: session, pushNotificationManager: pushNotificationManager, notificationCenter: notificationCenter)
    
        pushNotificationManager.pushToken = "the current push token"
        var finished = false
        var error: Error? = nil
        registrationService.register(completionHandler: { r in
            finished = true
            if case .failure(let e) = r {
                error = e
            }
        })
        
        // Verify the first request
        let registrationRequestData = (session.requestSent as! RegistrationRequest).body!
        let registrationResponse = try JSONDecoder().decode(ExpectedRegistrationRequestBody.self, from: registrationRequestData)
        XCTAssertEqual(registrationResponse.pushToken, "the current push token")
        
        // Respond to the first request
        session.requestSent = nil
        session.executeCompletion!(Result<(), Error>.success(()))
        
        // Simulate the notification containing the activationCode.
        // This should trigger the second request.
        // TODO: Ideally we would test this in integration with the code that actually parses &
        // dispatches the notification.
        let activationCode = "a3d2c477-45f5-4609-8676-c24558094600"
        pushNotificationManager.handlers[.registrationActivationCode]?(["activationCode": activationCode]) { _ in }
        
        // Verify the second request
        let confirmRegistrationRequest = (session.requestSent as! ConfirmRegistrationRequest).body!
        let confirmResponse = try JSONDecoder().decode(ExpectedConfirmRegistrationRequestBody.self, from: confirmRegistrationRequest)
        XCTAssertEqual(confirmResponse.activationCode, UUID(uuidString: activationCode))
        XCTAssertEqual(confirmResponse.pushToken, "the current push token")
        
        XCTAssertFalse(finished)
        
        // Respond to the second request
        let confirmationResponse = ConfirmRegistrationResponse(id: id, secretKey: secretKey)
        session.executeCompletion!(Result<ConfirmRegistrationResponse, Error>.success(confirmationResponse))
        
        XCTAssertTrue(finished)
        XCTAssertNil(error)
        let storedRegistration = try SecureRegistrationStorage.shared.get()
        XCTAssertNotNil(storedRegistration)
        XCTAssertEqual(id, storedRegistration!.id)
        XCTAssertEqual(storedRegistration!.secretKey, secretKey)
        
        XCTAssertEqual(storedRegistration?.id, self.id)
        XCTAssertEqual(storedRegistration?.secretKey, self.secretKey)

        XCTAssertNotNil(observer.lastNotification)
        let notifiedRegistration = observer.lastNotification?.userInfo?[RegistrationCompleteNotificationRegistrationKey] as? Registration
        XCTAssertEqual(notifiedRegistration, storedRegistration)
    }
    
    func testRegistration_withoutPreExistingPushToken() throws {
        let session = SessionDouble()
        let pushNotificationMananger = PushNotificationManagerDouble()
        let notificationCenter = NotificationCenter()
        let observer = NotificationObserverDouble(notificationCenter: notificationCenter, notificationName: RegistrationCompleteNotification)
        let registrationService = ConcreteRegistrationService(session: session, pushNotificationManager: pushNotificationMananger, notificationCenter: notificationCenter)

        var finished = false
        var error: Error? = nil
        registrationService.register(completionHandler: { r in
            finished = true
            if case .failure(let e) = r {
                error = e
            }
        })
        
        XCTAssertNil(session.requestSent)

        // Simulate receiving the push token
        // TODO: Ideally we would test this in integration with the code that actually parses &
        // dispatches the notification.
        pushNotificationMananger.pushToken = "a push token"
        notificationCenter.post(name: PushTokenReceivedNotification, object: nil, userInfo: nil)
        // Verify the first request
        let registrationBody = (session.requestSent as! RegistrationRequest).body!
        let registrationPayload = try JSONDecoder().decode(ExpectedRegistrationRequestBody.self, from: registrationBody)
        XCTAssertEqual(registrationPayload.pushToken, "a push token")

        // Respond to the first request
        session.requestSent = nil
        session.executeCompletion!(Result<(), Error>.success(()))

        // Simulate the notification containing the activationCode.
        // This should trigger the second request.
        // TODO: Ideally we would test this in integration with the code that actually parses &
        // dispatches the notification.
        let activationCode = "a3d2c477-45f5-4609-8676-c24558094600"
        pushNotificationMananger.handlers[.registrationActivationCode]?(["activationCode": activationCode]) { _ in }

        // Verify the second request
        let confirmRegistrationBody = (session.requestSent as! ConfirmRegistrationRequest).body!
        let confirmRegistrationPayload = try JSONDecoder().decode(ExpectedConfirmRegistrationRequestBody.self, from: confirmRegistrationBody)
        XCTAssertEqual(confirmRegistrationPayload.activationCode, UUID(uuidString: activationCode))
        XCTAssertEqual(confirmRegistrationPayload.pushToken, "a push token")

        XCTAssertFalse(finished)

        // Respond to the second request
        let confirmationResponse = ConfirmRegistrationResponse(id: id, secretKey: secretKey)
        session.executeCompletion!(Result<ConfirmRegistrationResponse, Error>.success(confirmationResponse))

        XCTAssertTrue(finished)
        XCTAssertNil(error)
        let storedRegistration = try SecureRegistrationStorage.shared.get()
        XCTAssertNotNil(storedRegistration)
        XCTAssertEqual(id, storedRegistration!.id)
        XCTAssertEqual(storedRegistration!.secretKey, secretKey)

        XCTAssertEqual(storedRegistration?.id, self.id)
        XCTAssertEqual(storedRegistration?.secretKey, self.secretKey)

        XCTAssertNotNil(observer.lastNotification)
        let notifiedRegistration = observer.lastNotification?.userInfo?[RegistrationCompleteNotificationRegistrationKey] as? Registration
        XCTAssertEqual(notifiedRegistration, storedRegistration)
    }
}

class SessionDouble: Session {
   let delegateQueue = OperationQueue.current!

   var requestSent: Any?
   var executeCompletion: ((Any) -> Void)?

    func execute<R: Request>(_ request: R, queue: OperationQueue, completion: @escaping (Result<R.ResponseType, Error>) -> Void) {
       requestSent = request
       executeCompletion = { result in
           completion(result as! Result<R.ResponseType, Error>)
       }
   }
}

private struct ExpectedRegistrationRequestBody: Codable {
    let pushToken: String
}

private struct ExpectedConfirmRegistrationRequestBody: Codable {
    let activationCode: UUID
    let pushToken: String
}
