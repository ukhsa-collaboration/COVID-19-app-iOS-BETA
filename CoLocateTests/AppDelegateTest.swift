//
//  AppDelegateTest.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import XCTest
@testable import CoLocate

class AppDelegateTest: XCTestCase {

    private var appDelegate: AppDelegate!

    private var nursery: BluetoothNurseryDouble!
    private var persistence: PersistenceDouble!
    private var dispatcher: RemoteNotificationDispatcherDouble!
    private var remoteNotificationManager: RemoteNotificationManagerDouble!
    private var registrationService: RegistrationServiceDouble!
    
    override func setUp() {
        nursery = BluetoothNurseryDouble()
        persistence = PersistenceDouble()
        dispatcher = RemoteNotificationDispatcherDouble()
        remoteNotificationManager = RemoteNotificationManagerDouble()
        registrationService = RegistrationServiceDouble()
        
        appDelegate = AppDelegate()
        appDelegate.bluetoothNursery = nursery
        appDelegate.persistence = persistence
        appDelegate.dispatcher = dispatcher
        appDelegate.remoteNotificationManager = remoteNotificationManager
        appDelegate.registrationService = registrationService
    }

    func testLaunchingWithoutBluetoothPermissons_DoesNotStartBluetooth() throws {
        appDelegate.persistence = PersistenceDouble(registration: nil, bluetoothPermissionRequested: false)
        
        _ = appDelegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)

        XCTAssertFalse(nursery.hasStarted)
        XCTAssertFalse(nursery.createListenerCalled)
        XCTAssertFalse(nursery.createBroadcasterCalled)
    }
    
    func testLaunchingWithBluetoothPermissionRequested_StartsNursery() {
        appDelegate.persistence = PersistenceDouble(registration: nil, bluetoothPermissionRequested: true)
        
        _ = appDelegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)

        XCTAssertTrue(nursery.hasStarted)
        XCTAssertFalse(nursery.createListenerCalled)
        XCTAssertFalse(nursery.createBroadcasterCalled)
    }
        
    func testLaunchingWithRegistration_StartsNursery() {
        persistence.registration = Registration.fake
        persistence.bluetoothPermissionRequested = true

        _ = appDelegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)

        XCTAssertTrue(nursery.hasStarted)
        XCTAssertFalse(nursery.createListenerCalled)
        XCTAssertFalse(nursery.createBroadcasterCalled)
        XCTAssertEqual(nursery.registrationPassedToStartBluetooth, persistence.registration)
    }
    
    func testLaunchingWithRegistration_StartsNursery_evenWithoutBluetoothPermissionRequested() {
        // Tests the case where the user registered on an old build that didn't record bluetoothPermissionRequested
        appDelegate.persistence = PersistenceDouble(registration: .fake, bluetoothPermissionRequested: false)
        
        _ = appDelegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)

        XCTAssertTrue(nursery.hasStarted)
        XCTAssertFalse(nursery.createListenerCalled)
        XCTAssertFalse(nursery.createBroadcasterCalled)
    }

}


fileprivate class RemoteNotificationDispatcherDouble: RemoteNotificationDispatching {
    var pushToken: String?

    func registerHandler(forType type: RemoteNotificationType, handler: @escaping RemoteNotificationHandler) {

    }
    func removeHandler(forType type: RemoteNotificationType) {

    }

    func hasHandler(forType type: RemoteNotificationType) -> Bool {
        return false
    }

    func handleNotification(userInfo: [AnyHashable : Any], completionHandler: @escaping RemoteNotificationCompletionHandler) {

    }

    func receiveRegistrationToken(fcmToken: String) {
        
    }
}
