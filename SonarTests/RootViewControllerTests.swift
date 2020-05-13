//
//  RootViewControllerTests.swift
//  SonarTests
//
//  Created by NHSX on 4/14/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import Sonar

class RootViewControllerTests: TestCase {
    
    private var persistence: PersistenceDouble!
    private var authorizationManager: AuthorizationManagerDouble!
    private var remoteNotificationDispatcher: RemoteNotificationDispatcher!
    private var notificationCenter: NotificationCenter!
    private var bluetoothNursery: BluetoothNurseryDouble!
    private var onboardingCoordinator: OnboardingCoordinatorDouble!
    private var monitor: AppMonitoringDouble!
    private var rootVC: RootViewController!
    
    override func setUp() {
        super.setUp()
        
        persistence = PersistenceDouble()
        authorizationManager = AuthorizationManagerDouble()
        remoteNotificationDispatcher = makeDispatcher()
        notificationCenter = NotificationCenter()
        bluetoothNursery = BluetoothNurseryDouble()
        onboardingCoordinator = OnboardingCoordinatorDouble()
        monitor = AppMonitoringDouble()
        
        rootVC = RootViewController()
        rootVC.inject(
            persistence: persistence,
            authorizationManager: authorizationManager,
            remoteNotificationManager: RemoteNotificationManagerDouble(dispatcher: remoteNotificationDispatcher),
            notificationCenter: notificationCenter,
            registrationService: RegistrationServiceDouble(),
            bluetoothNursery: bluetoothNursery,
            onboardingCoordinator: onboardingCoordinator,
            monitor: monitor,
            session: SessionDouble(),
            contactEventsUploader: ContactEventsUploaderDouble(),
            linkingIdManager: LinkingIdManagerDouble(),
            statusStateMachine: StatusStateMachiningDouble(),
            uiQueue: QueueDouble(),
            userStatusProvider: UserStatusProvider(localeProvider: EnGbLocaleProviderDouble())
        )
    }
    
    func testInitialVC_OnboardingRequired() {
        onboardingCoordinator.isOnboardingRequired = true
        XCTAssertNotNil(rootVC.view)
        
        XCTAssertEqual(rootVC.children.count, 1)
        XCTAssertNotNil(rootVC.children.first as? OnboardingViewController)
        XCTAssertTrue(monitor.detectedEvents.isEmpty)
    }
    
    func testInitialVC_OnboardingNotRequired() {
        onboardingCoordinator.isOnboardingRequired = false
        XCTAssertNotNil(rootVC.view)
        
        XCTAssertEqual(rootVC.children.count, 1)
        let navController = rootVC.children.first as! UINavigationController
        XCTAssertEqual(navController.children.count, 1)
        XCTAssertNotNil(navController.children[0] as? StatusViewController)
        XCTAssertTrue(monitor.detectedEvents.isEmpty)
    }
    
    func testOnboardingFinished() {
        onboardingCoordinator.isOnboardingRequired = true
        
        XCTAssertNotNil(rootVC.view)
                
        onboardingCoordinator.stateCompletion?(.done)

        XCTAssertEqual(rootVC.children.count, 1)
        let navController = rootVC.children.first as! UINavigationController
        XCTAssertEqual(navController.children.count, 1)
        XCTAssertNotNil(navController.children[0] as? StatusViewController)
        XCTAssertEqual(monitor.detectedEvents, [.onboardingCompleted])
    }
    
    func testShow() {
        let child = UIViewController()
        XCTAssertNotNil(rootVC.view) // trigger viewDidLoad before we call show
        
        rootVC.show(viewController: child)
        
        XCTAssertEqual(rootVC.children, [child])
    }
    
    func testBecomeActiveShowsPermissionDeniedWhenNoBluetoothPermission() {
        onboardingCoordinator.isOnboardingRequired = false
        persistence.registration = .fake
        authorizationManager.bluetooth = .allowed
        bluetoothNursery.stateObserver = BluetoothStateObserver(initialState: .poweredOn)

        parentViewControllerForTests.viewControllers = [rootVC]

        XCTAssertNil(rootVC.presentedViewController)

        authorizationManager.bluetooth = .denied
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        authorizationManager.notificationsCompletion?(.allowed)
        
        XCTAssertNotNil(rootVC.presentedViewController as? BluetoothPermissionDeniedViewController)
    }
    
    func testBecomesActiveShowsBluetoothOffWhenBluetoothOff() {
        onboardingCoordinator.isOnboardingRequired = false
        bluetoothNursery.startBluetooth(registration: nil)
        authorizationManager.bluetooth = .allowed
        parentViewControllerForTests.viewControllers = [rootVC]

        XCTAssertNil(rootVC.presentedViewController)

        bluetoothNursery.stateObserver.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOff)
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        authorizationManager.notificationsCompletion?(.allowed)

        XCTAssertNotNil(rootVC.presentedViewController as? BluetoothOffViewController)
    }
    
    func testBecomeActiveDoesNotShowPermissionProblemsDuringOnboarding() {
        onboardingCoordinator.isOnboardingRequired = false
        parentViewControllerForTests.viewControllers = [rootVC]
        XCTAssertNotNil(rootVC.view)
        
        authorizationManager.bluetooth = .denied
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        authorizationManager.notificationsCompletion?(.allowed)
        
        XCTAssertNil(rootVC.presentedViewController)
    }

    
    func testBecomeActiveDoesNotShowPermissionDeniedWhenAllPermissionsGranted() {
        onboardingCoordinator.isOnboardingRequired = false
        persistence.registration = .fake
        authorizationManager.bluetooth = .allowed
        parentViewControllerForTests.viewControllers = [rootVC]
        
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        authorizationManager.notificationsCompletion?(.allowed)
        
        XCTAssertNil(rootVC.presentedViewController)
    }
    
    func testBecomeActiveHidesExistingPermissionDeniedWhenAllPermissionsGranted() {
        onboardingCoordinator.isOnboardingRequired = false
        persistence.registration = .fake
        authorizationManager.bluetooth = .denied
        bluetoothNursery.startBluetooth(registration: nil)
        
        parentViewControllerForTests.viewControllers = [rootVC]
        
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        authorizationManager.notificationsCompletion?(.allowed)
        bluetoothNursery.stateObserver.btleListener(BTLEListenerDouble(), didUpdateState: .unauthorized)
        XCTAssertNotNil(rootVC.presentedViewController)
        
        authorizationManager.bluetooth = .allowed
        bluetoothNursery.stateObserver.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOn)
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        authorizationManager.notificationsCompletion?(.allowed)
        
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
        done = true
    }
    
    func testUpdatesSubviewsOnFontSizeChange() {
        let intermediate = UIView()
        let updates = UpdatesBasedOnAccessibilityDisplayChangesDouble()
        intermediate.addSubview(updates)
        rootVC.view.addSubview(intermediate)
        
        notificationCenter.post(name: UIContentSizeCategory.didChangeNotification, object: nil)
         
        XCTAssertTrue(updates.updated)
    }

    func testUpdatesSubviewsOnInvertColorsChange() {
        let intermediate = UIView()
        let updates = UpdatesBasedOnAccessibilityDisplayChangesDouble()
        intermediate.addSubview(updates)
        rootVC.view.addSubview(intermediate)

        notificationCenter.post(name: UIAccessibility.invertColorsStatusDidChangeNotification, object: nil)

        XCTAssertTrue(updates.updated)
    }

    func testUpdatesPresentedViewsOnFontSizeChange() {
        parentViewControllerForTests.viewControllers = [rootVC]
        
        let intermediate = UIView()
        let updates = UpdatesBasedOnAccessibilityDisplayChangesDouble()
        intermediate.addSubview(updates)
        let presented = UIViewController()
        presented.view = UIView()
        presented.view.addSubview(intermediate)
        rootVC.present(presented, animated: false)
        
        notificationCenter.post(name: UIContentSizeCategory.didChangeNotification, object: nil)
         
        XCTAssertTrue(updates.updated)
    }

    func testUpdatesPresentedViewsInChildrenOnFontSizeChange() {
        parentViewControllerForTests.viewControllers = [rootVC]
        XCTAssertNotNil(rootVC.view) // Trigger showing the first view to get it out of the way

        let intermediate = UIViewController()
        rootVC.show(viewController: intermediate)

        let presented = UIViewController()
        presented.view = UIView()

        let updates = UpdatesBasedOnAccessibilityDisplayChangesDouble()
        presented.view.addSubview(updates)

        intermediate.present(presented, animated: false)

        notificationCenter.post(name: UIContentSizeCategory.didChangeNotification, object: nil)

        XCTAssertTrue(updates.updated)
    }
}

fileprivate func makeDispatcher() -> RemoteNotificationDispatcher {
    return RemoteNotificationDispatcher(notificationCenter: NotificationCenter(), userNotificationCenter: UserNotificationCenterDouble())
}

fileprivate class UpdatesBasedOnAccessibilityDisplayChangesDouble: UIView, UpdatesBasedOnAccessibilityDisplayChanges {
    var updated = false
    
    func updateBasedOnAccessibilityDisplayChanges() {
        updated = true
    }
}
