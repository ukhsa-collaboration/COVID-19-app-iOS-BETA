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
        let persistence = PersistenceDouble()
        let notificationCenter = NotificationCenter()
        let remoteNotificationDispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: UserNotificationCenterDouble(),
            persistence: persistence
        )
        let registrationService = ConcreteRegistrationService(session: session,
                                                              persistence: persistence,
                                                              remoteNotificationDispatcher: remoteNotificationDispatcher,
                                                              notificationCenter: notificationCenter)
    
        remoteNotificationDispatcher.pushToken = "the current push token"
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
        let activationCode = "a3d2c477-45f5-4609-8676-c24558094600"
        
        var remoteNotificatonCallbackCalled = false
        remoteNotificationDispatcher.handleNotification(userInfo: ["activationCode": activationCode]) { _ in
            remoteNotificatonCallbackCalled = true
        }
        
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

        let storedRegistration = persistence.registration
        XCTAssertNotNil(storedRegistration)
        XCTAssertEqual(id, storedRegistration?.id)
        XCTAssertEqual(secretKey, storedRegistration?.secretKey)
        
        // Make sure we cleaned up after ourselves
        XCTAssertTrue(remoteNotificatonCallbackCalled)
        XCTAssertFalse(remoteNotificationDispatcher.hasHandler(forType: .registrationActivationCode))
    }
    
    func testRegistration_withoutPreExistingPushToken() throws {
        let session = SessionDouble()
        let persistence = PersistenceDouble()
        let notificationCenter = NotificationCenter()
        let remoteNotificationDispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: UserNotificationCenterDouble(),
            persistence: persistence
        )
        let registrationService = ConcreteRegistrationService(session: session,
                                                              persistence: persistence,
                                                              remoteNotificationDispatcher: remoteNotificationDispatcher,
                                                              notificationCenter: notificationCenter)

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
        remoteNotificationDispatcher.receiveRegistrationToken(fcmToken: "a push token")
        // Verify the first request
        let registrationBody = (session.requestSent as! RegistrationRequest).body!
        let registrationPayload = try JSONDecoder().decode(ExpectedRegistrationRequestBody.self, from: registrationBody)
        XCTAssertEqual(registrationPayload.pushToken, "a push token")

        // Respond to the first request
        session.requestSent = nil
        session.executeCompletion!(Result<(), Error>.success(()))

        // Simulate the notification containing the activationCode.
        // This should trigger the second request.
        let activationCode = "a3d2c477-45f5-4609-8676-c24558094600"
        var remoteNotificatonCallbackCalled = false
        remoteNotificationDispatcher.handleNotification(userInfo: ["activationCode": activationCode]) { _ in
            remoteNotificatonCallbackCalled = true
        }

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

        let storedRegistration = persistence.registration
        XCTAssertNotNil(storedRegistration)
        XCTAssertEqual(id, storedRegistration?.id)
        XCTAssertEqual(secretKey, storedRegistration?.secretKey)

        // Make sure we cleaned up after ourselves
        XCTAssertTrue(remoteNotificatonCallbackCalled)
        XCTAssertFalse(remoteNotificationDispatcher.hasHandler(forType: .registrationActivationCode))
    }
    
    func testRegistration_cleansUpAfterInitialRequestFailure() throws {
        let session = SessionDouble()
        let persistence = PersistenceDouble()
        let notificationCenter = NotificationCenter()
        let remoteNotificationDispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: UserNotificationCenterDouble(),
            persistence: persistence
        )
        remoteNotificationDispatcher.pushToken = "the current push token"
        let registrationService = ConcreteRegistrationService(session: session,
                                                              persistence: persistence,
                                                              remoteNotificationDispatcher: remoteNotificationDispatcher,
                                                              notificationCenter: notificationCenter)

        registrationService.register(completionHandler: { _ in })
        
        session.requestSent = nil
        session.executeCompletion!(Result<(), Error>.failure(ErrorForTest()))

        // We should have unsusbscribed from push notifications.
        XCTAssertFalse(remoteNotificationDispatcher.hasHandler(forType: .registrationActivationCode))
        
        // We should also have unsubscribe from the PushTokenReceivedNotification. We can't test that directly but we can observe its effects.
        notificationCenter.post(name: PushTokenReceivedNotification, object: nil, userInfo: nil)
        XCTAssertNil(session.requestSent)
    }
    
    func testRegistration_ignoresResponseAfterCancelation() {
        let session = SessionDouble()
        let persistence = PersistenceDouble()
        let notificationCenter = NotificationCenter()
        let remoteNotificationDispatcher = RemoteNotificationDispatcher(
            notificationCenter: notificationCenter,
            userNotificationCenter: UserNotificationCenterDouble(),
            persistence: persistence
        )
        let registrationService = ConcreteRegistrationService(session: session,
                                                              persistence: persistence,
                                                              remoteNotificationDispatcher: remoteNotificationDispatcher,
                                                              notificationCenter: notificationCenter)
    
        remoteNotificationDispatcher.pushToken = "the current push token"
        var finished = false
        let attempt = registrationService.register(completionHandler: { r in finished = true })
        
        // Respond to the first request
        session.executeCompletion!(Result<(), Error>.success(()))
        
        // Simulate the notification containing the activationCode.
        // This should trigger the second request.
        remoteNotificationDispatcher.handleNotification(userInfo: ["activationCode": "arbitrary"]) { _ in }
        
        attempt.cancel()
                        
        // Respond to the second request
        let confirmationResponse = ConfirmRegistrationResponse(id: id, secretKey: secretKey)
        session.executeCompletion!(Result<ConfirmRegistrationResponse, Error>.success(confirmationResponse))
        
        XCTAssertFalse(finished)
        XCTAssertNil(persistence.registration)
        
        // We should have unsusbscribed from push notifications.
        XCTAssertFalse(remoteNotificationDispatcher.hasHandler(forType: .registrationActivationCode))
        
        // We should also have unsubscribed from the PushTokenReceivedNotification. We can't test that directly but we can observe its effects.
        session.requestSent = nil
        notificationCenter.post(name: PushTokenReceivedNotification, object: nil, userInfo: nil)
        XCTAssertNil(session.requestSent)
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
