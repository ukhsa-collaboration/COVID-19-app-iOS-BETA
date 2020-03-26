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

    func testRegistration() {
        let storyboard = UIStoryboard.init(name: "Registration", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "RegistrationViewController") as! RegistrationViewController
        XCTAssertNotNil(vc.view)

        let session = SessionDouble()
        vc.session = session

        vc.didTapRegister(vc.retryButton!)

        let registration = Registration(id: UUID(), secretKey: "super secret")
        session.executeCompletion!(.success(registration))

        let actualRegistration = try! SecureRegistrationStorage.shared.get()
        XCTAssertEqual(actualRegistration?.id, registration.id)
        XCTAssertEqual(actualRegistration?.secretKey, "super secret")
    }

    func testAlreadyRegistered() {
        let registration = Registration(id: UUID(), secretKey: "super secret")
        try! SecureRegistrationStorage.shared.set(registration: registration)

        let storyboard = UIStoryboard.init(name: "Registration", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "RegistrationViewController") as! RegistrationViewController
        XCTAssertNotNil(vc.view)

        let session = SessionDouble()
        let coordinator = AppCoordinatorDouble()

        vc.session = session
        vc.coordinator = coordinator

        inWindowHierarchy(viewController: vc) {
            vc.viewWillAppear(false)

            XCTAssertTrue(coordinator.enterDiagnosisWasCalled)
        }
    }

}

class SessionDouble: Session {
    let delegateQueue = OperationQueue.current!

    var executeCompletion: ((Result<Registration, Error>) -> Void)?
    func execute<R: Request>(_ request: R, queue: OperationQueue, completion: @escaping (Result<R.ResponseType, Error>) -> Void) {
        executeCompletion = ({ completion($0) } as! ((Result<Registration, Error>) -> Void))
    }
}

class AppCoordinatorDouble: AppCoordinator {
    var enterDiagnosisWasCalled = false

    init() {
        super.init(diagnosisService: DiagnosisService())
    }

    override func launchEnterDiagnosis() {
        enterDiagnosisWasCalled = true
    }
}
