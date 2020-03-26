//
//  RegistrationViewControllerTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class RegistrationViewControllerTests: XCTestCase {

    override class func setUp() {
        super.setUp()

        try! SecureRegistrationStorage.shared.clear()
    }

    func testRegistration_withPreExistingPushToken() throws {
        let storyboard = UIStoryboard.init(name: "Registration", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "RegistrationViewController") as! RegistrationViewController
        let appCoordinator = AppCoordinatorDouble()
        vc.coordinator = appCoordinator
        let notificationManager = NotificationManagerDouble()
        notificationManager.pushToken = "the current push token"
        vc.inject(notificationManager: notificationManager)
        XCTAssertNotNil(vc.view)
        vc.viewDidLoad()
        vc.viewWillAppear(false)

        let session = SessionDouble()
        vc.session = session

        vc.didTapRegister(vc.retryButton!)
        
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
        
        XCTAssertFalse(appCoordinator.enterDiagnosisWasCalled)
        
        // Respond to the second request
        let id = UUID()
        let secretKey = "a secret key".data(using: .utf8)!
        let confirmationResponse = ConfirmRegistrationResponse(id: id, secretKey: secretKey)
        session.executeCompletion!(Result<ConfirmRegistrationResponse, Error>.success(confirmationResponse))
        
        XCTAssertTrue(appCoordinator.enterDiagnosisWasCalled)
        let registration = try SecureRegistrationStorage.shared.get()
        XCTAssertNotNil(registration)
        XCTAssertEqual(id, registration!.id)
        XCTAssertEqual(registration!.secretKey, secretKey)
    }
}

class NotificationManagerDouble: NotificationManager {
    var pushToken: String?
    
    var delegate: NotificationManagerDelegate?
    
    func requestAuthorization(application: Application, completion: @escaping (Result<Bool, Error>) -> Void) {
    }
    
    func handleNotification(userInfo: [AnyHashable : Any]) {
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

class AppCoordinatorDouble: AppCoordinator {
    var enterDiagnosisWasCalled = false

    init() {
        super.init(diagnosisService: DiagnosisService(), notificationManager: NotificationManagerDouble())
    }

    override func launchEnterDiagnosis() {
        enterDiagnosisWasCalled = true
    }
    
    var okNowWasCalled = false
    
    override func launchOkNowVC() {
        okNowWasCalled = true
    }
}

private struct ExpectedRegistrationRequestBody: Codable {
    let pushToken: String
}

private struct ExpectedConfirmRegistrationRequestBody: Codable {
    let activationCode: UUID
    let pushToken: String
}
