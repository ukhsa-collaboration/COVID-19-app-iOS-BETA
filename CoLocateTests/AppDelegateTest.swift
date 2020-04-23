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

    var appDelegate: AppDelegate!

    var nursery: MockBluetoothNursery!
    var persistence: PersistenceDouble!
    var dispatcher: RemoteNotificationDispatcherDouble!
    var remoteNotificationManager: RemoteNotificationManagerDouble!
    var registrationService: RegistrationServiceDouble!
    var authorizationManager: AuthorizationManagerDouble!
    
    override func setUp() {
        nursery = MockBluetoothNursery()
        persistence = PersistenceDouble()
        dispatcher = RemoteNotificationDispatcherDouble()
        registrationService = RegistrationServiceDouble()
        authorizationManager = AuthorizationManagerDouble()
        authorizationManager.bluetooth = .notDetermined
        remoteNotificationManager = RemoteNotificationManagerDouble()

        appDelegate = AppDelegate()
        appDelegate.dispatcher = dispatcher
        appDelegate.persistence = persistence
        appDelegate.bluetoothNursery = nursery
        appDelegate.registrationService = registrationService
        appDelegate.authorizationManager = authorizationManager
        appDelegate.remoteNotificationManager = remoteNotificationManager
    }

    func testFirstAppLaunchDoesNotStartBluetooth() throws {
        authorizationManager.bluetooth = .notDetermined
        persistence.registration = nil

        _ = appDelegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)

        XCTAssertFalse(nursery.createListenerCalled)
        XCTAssertFalse(nursery.createBroadcasterCalled)
    }
    
    func testLaunchingWithBluetoothPermissionRequested_StartsListener() {
        authorizationManager.bluetooth = .allowed
        persistence.registration = nil
        
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

}

class MockBluetoothNursery: BluetoothNursery {
    
    var contactEventRepository: ContactEventRepository = DummyContactEventRepository()
    
    var contactEventPersister: ContactEventPersister = DummyContactEventPersister()
    
    var createListenerCalled = false
    var createBroadcasterCalled = false
    
    func createListener(stateDelegate: BTLEListenerStateDelegate?) {
        self.createListenerCalled = true
    }
    
    func createBroadcaster(stateDelegate: BTLEBroadcasterStateDelegate?, registration: Registration) {
        self.createBroadcasterCalled = true
    }
    
}

class DummyContactEventRepository: ContactEventRepository {
    var contactEvents: [ContactEvent] = []
    func reset() {
    }
    func removeExpiredContactEvents(ttl: Double) {
    }
    
    func btleListener(_ listener: BTLEListener, didFind sonarId: Data, forPeripheral peripheral: BTLEPeripheral) {
    }
    func btleListener(_ listener: BTLEListener, didReadRSSI RSSI: Int, forPeripheral peripheral: BTLEPeripheral) {
    }
}

class DummyContactEventPersister: ContactEventPersister {
    var items: [UUID: ContactEvent] = [:]
    func reset() {
    }
}

class RemoteNotificationDispatcherDouble: RemoteNotificationDispatching {
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
