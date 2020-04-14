//
//  RootViewControllerTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class RootViewControllerTests: TestCase {
    
    func testInitialVC_registered() {
        let persistence = PersistenceDouble(registration: Registration(id: UUID(), secretKey: Data()))
        let rootVC = makeRootVC(persistence: persistence)
        XCTAssertNotNil(rootVC.view)
        
        XCTAssertEqual(rootVC.children.count, 1)
        XCTAssertNotNil(rootVC.children.first as? StatusViewController)
    }
    
    func testInitialVC_notRegistered() {
        let rootVC = makeRootVC(persistence: PersistenceDouble(registration: nil))
        XCTAssertNotNil(rootVC.view)
        
        XCTAssertEqual(rootVC.children.count, 1)
        XCTAssertNotNil(rootVC.children.first as? OnboardingViewController)
    }
    
    func testOnboardingFinished() {
        let authMgr = AuthorizationManagerDouble(bluetooth: .allowed)
        let persistence = PersistenceDouble(allowedDataSharing: true, registration: nil, partialPostcode: "1234")
        let rootVC = makeRootVC(persistence: persistence, authorizationManager: authMgr)
        XCTAssertNotNil(rootVC.view)
        
        guard (rootVC.children.first as? OnboardingViewController) != nil else {
            XCTFail("Expected an OnboardingViewController but got something else")
            return
        }
        
        XCTAssertNotNil(authMgr.notificationsCompletion)
        authMgr.notificationsCompletion?(.allowed)

        XCTAssertNotNil(rootVC.children.first as? StatusViewController)
    }
    
    func testPotentialNotification() {
        let persistence = PersistenceDouble(registration: Registration(id: UUID(), secretKey: Data()))
        let dispatcher = makeDispatcher()
        let rootVC = makeRootVC(persistence: persistence, remoteNotificationDispatcher: dispatcher)
        XCTAssertNotNil(rootVC.view)
        
        guard let statusVC = rootVC.children.first as? StatusViewController else {
            XCTFail("Expected a StatusViewController but got something else")
            return
        }
        
        dispatcher.handleNotification(userInfo: ["status": "Potential"]) {_ in}
        
        XCTAssertFalse(statusVC.diagnosisTitleLabel.isHidden)
        XCTAssertEqual(statusVC.diagnosisTitleLabel.text, "You have been near someone who has coronavirus symptoms")
    }

    func testShow() {
        let rootVC = makeRootVC()
        let child = UIViewController()
        XCTAssertNotNil(rootVC.view) // trigger viewDidLoad before we call show
        
        rootVC.show(viewController: child)
        
        XCTAssertEqual(rootVC.children, [child])
    }
    
    func testBecomeActiveShowsPermissionDeniedWhenNoBluetoothPermission() {
        let persistence = PersistenceDouble(registration: Registration(id: UUID(), secretKey: Data()))
        let authMgr = AuthorizationManagerDouble(bluetooth: .allowed)
        let notificationCenter = NotificationCenter()
        let rootVC = makeRootVC(persistence: persistence, authorizationManager: authMgr, notificationCenter: notificationCenter)
        parentViewControllerForTests.viewControllers = [rootVC]
        
        authMgr.bluetooth = .denied
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        authMgr.notificationsCompletion?(.allowed)
        
        XCTAssertNotNil(rootVC.presentedViewController as? PermissionsDeniedViewController)
    }
    
    func testBecomeActiveShowsPermissionDeniedWhenNoNotificationPermission() {
        let persistence = PersistenceDouble(registration: Registration(id: UUID(), secretKey: Data()))
        let authMgr = AuthorizationManagerDouble(bluetooth: .allowed)
        let notificationCenter = NotificationCenter()
        let rootVC = makeRootVC(persistence: persistence, authorizationManager: authMgr, notificationCenter: notificationCenter)
        parentViewControllerForTests.viewControllers = [rootVC]
        
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        authMgr.notificationsCompletion?(.denied)
        
        XCTAssertNotNil(rootVC.presentedViewController as? PermissionsDeniedViewController)
    }
    
    func testBecomeActiveDoesNotShowPermissionDeniedWhenAllPermissionsGranted() {
        let persistence = PersistenceDouble(registration: Registration(id: UUID(), secretKey: Data()))
        let authMgr = AuthorizationManagerDouble(bluetooth: .allowed)
        let notificationCenter = NotificationCenter()
        let rootVC = makeRootVC(persistence: persistence, authorizationManager: authMgr, notificationCenter: notificationCenter)
        parentViewControllerForTests.viewControllers = [rootVC]
        
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        authMgr.notificationsCompletion?(.allowed)
        
        XCTAssertNil(rootVC.presentedViewController)
    }
    
    func testBecomeActiveHidesExistingPermissionDeniedWhenAllPermissionsGranted() {
        let persistence = PersistenceDouble(registration: Registration(id: UUID(), secretKey: Data()))
        let authMgr = AuthorizationManagerDouble(bluetooth: .allowed)
        let notificationCenter = NotificationCenter()
        let rootVC = makeRootVC(persistence: persistence, authorizationManager: authMgr, notificationCenter: notificationCenter)
        parentViewControllerForTests.viewControllers = [rootVC]
        
        rootVC.present(PermissionsDeniedViewController.instantiate(), animated: false, completion: nil)
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        authMgr.notificationsCompletion?(.allowed)
        
        let expectation = XCTestExpectation(description: "Presented view controller became nil")
        var done = false
        
        func pollPresentedVC() {
            if rootVC.presentedViewController == nil {
                expectation.fulfill()
            } else if !done {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: { pollPresentedVC() })
            }
        }
        
        pollPresentedVC()
        wait(for: [expectation], timeout: 2.0)
        done = false

        XCTAssertNil(rootVC.presentedViewController)
    }
}

fileprivate func makeRootVC(
    persistence: Persisting = PersistenceDouble(),
    authorizationManager: AuthorizationManaging = AuthorizationManagerDouble(),
    remoteNotificationDispatcher: RemoteNotificationDispatcher = makeDispatcher(),
    notificationCenter: NotificationCenter = NotificationCenter()
) -> RootViewController {
    let vc = RootViewController()
    vc.inject(
        persistence: persistence,
        authorizationManager: authorizationManager,
        remoteNotificationManager: RemoteNotificationManagerDouble(dispatcher: remoteNotificationDispatcher),
        notificationCenter: notificationCenter,
        registrationService: RegistrationServiceDouble(),
        contactEventRepository: ContactEventRepositoryDouble(),
        session: SessionDouble(),
        uiQueue: QueueDouble()
    )
    return vc
}

fileprivate func makeDispatcher() -> RemoteNotificationDispatcher {
    return RemoteNotificationDispatcher(notificationCenter: NotificationCenter(), userNotificationCenter: UserNotificationCenterDouble())
}
