//
//  RegistrationServiceTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class RegistrationServiceTests: XCTestCase {

    override class func setUp() {
        super.setUp()

        try! SecureRegistrationStorage.shared.clear()
    }

    func testRegistration_withPreExistingPushToken() throws {
        let session = SessionDouble()
        let notificationManager = NotificationManagerDouble()
        let registrationService = ConcreteRegistrationService(session: session, notificationManager: notificationManager)
    
        notificationManager.pushToken = "the current push token"
        var finished = false
        var error: Error? = nil
        registrationService.register(completionHandler: { r in
            switch r {
            case .success(_):
                finished = true
            case .failure(let e):
                finished = true
                error = e
            }
        })
        
        // Verify the first request
        switch (session.requestSent as! RegistrationRequest).method {
        case .post(let data):
            let payload = try JSONDecoder().decode(ExpectedRegistrationRequestBody.self, from: data)
            XCTAssertEqual(payload.pushToken, "the current push token")
        default:
            XCTFail("Expected a POST request")
        }
        
        // Respond to the first request
        session.requestSent = nil
        session.executeCompletion!(Result<(), Error>.success(()))
        
        // Simulate the notification containing the authorizationCode.
        // This should trigger the second request.
        let activationCode = "a3d2c477-45f5-4609-8676-c24558094600"
        notificationManager.delegate!.notificationManager(notificationManager, didReceiveNotificationWithInfo: ["activationCode": activationCode])
        
        // Verify the second request
        switch (session.requestSent as! ConfirmRegistrationRequest).method {
        case .post(let data):
            let payload = try JSONDecoder().decode(ExpectedConfirmRegistrationRequestBody.self, from: data)
            XCTAssertEqual(payload.activationCode, UUID(uuidString: activationCode))
            XCTAssertEqual(payload.pushToken, "the current push token")
            default:
                XCTFail("Expected a POST request")
        }
        
        XCTAssertFalse(finished)
        
        // Respond to the second request
        let id = UUID()
        let secretKey = "a secret key".data(using: .utf8)!
        let confirmationResponse = ConfirmRegistrationResponse(id: id, secretKey: secretKey)
        session.executeCompletion!(Result<ConfirmRegistrationResponse, Error>.success(confirmationResponse))
        
        XCTAssertTrue(finished)
        XCTAssertNil(error)
        let registration = try SecureRegistrationStorage.shared.get()
        XCTAssertNotNil(registration)
        XCTAssertEqual(id, registration!.id)
        XCTAssertEqual(registration!.secretKey, secretKey)
    }
    
    
    func testRegistration_withoutPreExistingPushToken() throws {
        let session = SessionDouble()
        let notificationManager = NotificationManagerDouble()
        let registrationService = ConcreteRegistrationService(session: session, notificationManager: notificationManager)
    
        var finished = false
        var error: Error? = nil
        registrationService.register(completionHandler: { r in
            switch r {
            case .success(_):
                finished = true
            case .failure(let e):
                finished = true
                error = e
            }
        })
        
        XCTAssertNil(session.requestSent)

        // Simulate receiving the push token
        notificationManager.pushToken = "a push token"
        notificationManager.delegate!.notificationManager(notificationManager, didObtainPushToken: "a push token")
        
        // Verify the first request
        switch (session.requestSent as! RegistrationRequest).method {
        case .post(let data):
            let payload = try JSONDecoder().decode(ExpectedRegistrationRequestBody.self, from: data)
            XCTAssertEqual(payload.pushToken, "a push token")
        default:
            XCTFail("Expected a POST request")
        }
        
        // Respond to the first request
        session.requestSent = nil
        session.executeCompletion!(Result<(), Error>.success(()))
        
        // Simulate the notification containing the authorizationCode.
        // This should trigger the second request.
        let activationCode = "a3d2c477-45f5-4609-8676-c24558094600"
        notificationManager.delegate!.notificationManager(notificationManager, didReceiveNotificationWithInfo: ["activationCode": activationCode])
        
        // Verify the second request
        switch (session.requestSent as! ConfirmRegistrationRequest).method {
        case .post(let data):
            let payload = try JSONDecoder().decode(ExpectedConfirmRegistrationRequestBody.self, from: data)
            XCTAssertEqual(payload.activationCode, UUID(uuidString: activationCode))
            XCTAssertEqual(payload.pushToken, "a push token")
            default:
                XCTFail("Expected a POST request")
        }
        
        XCTAssertFalse(finished)
        
        // Respond to the second request
        let id = UUID()
        let secretKey = "a secret key".data(using: .utf8)!
        let confirmationResponse = ConfirmRegistrationResponse(id: id, secretKey: secretKey)
        session.executeCompletion!(Result<ConfirmRegistrationResponse, Error>.success(confirmationResponse))
        
        XCTAssertTrue(finished)
        XCTAssertNil(error)
        let registration = try SecureRegistrationStorage.shared.get()
        XCTAssertNotNil(registration)
        XCTAssertEqual(id, registration!.id)
        XCTAssertEqual(registration!.secretKey, secretKey)
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
