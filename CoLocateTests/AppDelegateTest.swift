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
    
    override func setUp() {
        nursery = MockBluetoothNursery()
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

    func testFirstAppLaunchDoesNothing() throws {
        _ = appDelegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)

        // THINK : are these tests necessary and sufficient ?
        XCTAssertFalse(nursery.startListenerCalled)
        XCTAssertFalse(nursery.startBroadcasterCalled)
    }
    
    func testStartingWithRegistrationAfterForceQuitStartsListenerAndBroadcaster() {
        appDelegate.persistence = PersistenceDouble(registration: Registration.fake)

        _ = appDelegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)

        // THINK -- does this assert what we want ?
        XCTAssertTrue(nursery.startListenerCalled)
        XCTAssertTrue(nursery.startBroadcasterCalled)
    }

}

class MockBluetoothNursery: BluetoothNursery {
    
    var contactEventRepository: ContactEventRepository = DummyContactEventRepository()
    
    var contactEventPersister: ContactEventPersister = DummyContactEventPersister()
    
    var startBroadcasterCalled = false
    var startListenerCalled = false
    
    func startBroadcaster(stateDelegate: BTLEBroadcasterStateDelegate?) {
        self.startBroadcasterCalled = true
    }
    
    func startListener(stateDelegate: BTLEListenerStateDelegate?) {
        self.startListenerCalled = true
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
