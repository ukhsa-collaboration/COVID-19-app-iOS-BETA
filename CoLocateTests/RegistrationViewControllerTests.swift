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
        let notificationManager = NotificationManagerDouble()
        notificationManager.pushToken = "the current push token"
        vc.inject(notificationManager: notificationManager)
        XCTAssertNotNil(vc.view)

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
    var executeCompletion: ((Result<(), Error>) -> Void)?
    
    func execute<R: Request>(_ request: R, queue: OperationQueue, completion: @escaping (Result<R.ResponseType, Error>) -> Void) {
        requestSent = request
        executeCompletion = ({ completion($0) } as! ((Result<(), Error>) -> Void))
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
