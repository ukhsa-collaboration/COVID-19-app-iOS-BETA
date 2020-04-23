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

        // Question : are these assertions easy enough to read ?
        XCTAssertFalse(nursery.createListenerCalled)
        XCTAssertFalse(nursery.createBroadcasterCalled)

        XCTAssertFalse(nursery.restoreListenerCalled)
        XCTAssertFalse(nursery.restoreListenerCalled)
    }
    
    func testStartingWithRegistrationWithNoStateRestorationStartsListenerAndBroadcaster() {
        appDelegate.persistence = PersistenceDouble(registration: Registration.fake)

        _ = appDelegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)

        XCTAssertTrue(nursery.createListenerCalled)
        XCTAssertTrue(nursery.createBroadcasterCalled)

        XCTAssertFalse(nursery.restoreListenerCalled)
        XCTAssertFalse(nursery.restoreListenerCalled)
    }

    func testStartingWithRegistrationAndStateRestoration_recreatesFromLaunchIdentifiers() {
        appDelegate.persistence = PersistenceDouble(registration: Registration.fake)

        let launchOptions = [
            UIApplication.LaunchOptionsKey.bluetoothPeripherals: ["restoreA"],
            UIApplication.LaunchOptionsKey.bluetoothCentrals: ["restoreB"],
        ]
        _ = appDelegate.application(UIApplication.shared, didFinishLaunchingWithOptions: launchOptions)

        // do not make them from scratch
        XCTAssertFalse(nursery.createListenerCalled)
        XCTAssertFalse(nursery.createBroadcasterCalled)

        // remake them from the launch options
        XCTAssertTrue(nursery.restoreListenerCalled)
        XCTAssertTrue(nursery.restoreBroadcasterCalled)
    }

    func testStartingWithoutRegistrationWithStateRestorationStartsListener_butNotTheBroadcaster() {
        appDelegate.persistence = PersistenceDouble()

        let launchOptions = [
            UIApplication.LaunchOptionsKey.bluetoothPeripherals: ["restoreA"],
            UIApplication.LaunchOptionsKey.bluetoothCentrals: ["restoreB"],
        ]
        _ = appDelegate.application(UIApplication.shared, didFinishLaunchingWithOptions: launchOptions)

        XCTAssertTrue(nursery.restoreListenerCalled)
        XCTAssertFalse(nursery.restoreBroadcasterCalled)
        
        XCTAssertFalse(nursery.createListenerCalled)
        XCTAssertFalse(nursery.createBroadcasterCalled)
    }

}

class MockBluetoothNursery: BluetoothNursery {
    
    var contactEventRepository: ContactEventRepository = DummyContactEventRepository()
    
    var contactEventPersister: ContactEventPersister = DummyContactEventPersister()
    
    var createListenerCalled = false
    var createBroadcasterCalled = false
    
    var restoreListenerCalled = false
    var restoreBroadcasterCalled = false
    
    func createListener(stateDelegate: BTLEListenerStateDelegate?) {
        self.createListenerCalled = true
    }
    
    func createBroadcaster(stateDelegate: BTLEBroadcasterStateDelegate?, registration: Registration) {
        self.createBroadcasterCalled = true
    }
    
    func restoreListener(_ restorationIdentifiers: [String]) {
        self.restoreListenerCalled = true
    }

    func restoreBroadcaster(_ restorationIdentifiers: [String]) {
        self.restoreBroadcasterCalled = true
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
