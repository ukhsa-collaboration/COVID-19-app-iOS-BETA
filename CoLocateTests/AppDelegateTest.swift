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

    func testFirstAppLaunchDoesNotStartBluetooth() throws {
        appDelegate.persistence = PersistenceDouble(registration: nil, bluetoothPermissionRequested: false)
        
        _ = appDelegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)

        XCTAssertFalse(nursery.createListenerCalled)
        XCTAssertFalse(nursery.createBroadcasterCalled)
    }
    
    func testLaunchingWithBluetoothPermissionRequested_StartsListener() {
        appDelegate.persistence = PersistenceDouble(registration: nil, bluetoothPermissionRequested: true)
        
        _ = appDelegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)

        XCTAssertTrue(nursery.createListenerCalled)
        XCTAssertFalse(nursery.createBroadcasterCalled)
    }
    
    func testLaunchingWithRegistration_StartsListenerAndBroadcaster() {
        persistence.registration = Registration.fake

        _ = appDelegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)

        XCTAssertTrue(nursery.createListenerCalled)
        XCTAssertTrue(nursery.createBroadcasterCalled)
    }

    func testStartsBroadcastingOnceRegistrationIsPersisted() {
        persistence.registration = nil
        _ = appDelegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)
        persistence.registration = Registration.fake
        appDelegate.persistence(persistence, didUpdateRegistration: Registration.fake)

        XCTAssertTrue(nursery.createBroadcasterCalled)
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
