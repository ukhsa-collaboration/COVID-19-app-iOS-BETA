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
        XCTAssertFalse(nursery.startListenerCalled)
        XCTAssertFalse(nursery.startBroadcasterCalled)

        XCTAssertFalse(nursery.recreateListenerWasCalled)
        XCTAssertFalse(nursery.recreateBroadcasterWasCalled)
    }
    
    func testStartingWithRegistrationAfterForceQuitStartsListenerAndBroadcaster() {
        appDelegate.persistence = PersistenceDouble(registration: Registration.fake)

        _ = appDelegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)

        // Question : are these assertions easy enough to read ?
        //            and do they assert ENOUGH ?
        XCTAssertTrue(nursery.startListenerCalled)
        XCTAssertTrue(nursery.startBroadcasterCalled)

        XCTAssertFalse(nursery.recreateListenerWasCalled)
        XCTAssertFalse(nursery.recreateBroadcasterWasCalled)
    }

    func testStartingWithRegistrationAndStateRestoration_recreatesFromLaunchIdentifiers() {
        appDelegate.persistence = PersistenceDouble(registration: Registration.fake)

        let options: [UIApplication.LaunchOptionsKey: Any]? = [.bluetoothPeripherals: []]
        _ = appDelegate.application(UIApplication.shared, didFinishLaunchingWithOptions: options)

        // do not make them from scratch
        XCTAssertFalse(nursery.startListenerCalled)
        XCTAssertFalse(nursery.startBroadcasterCalled)

        // remake them from the launch options
        XCTAssertTrue(nursery.recreateListenerWasCalled)
        XCTAssertTrue(nursery.recreateBroadcasterWasCalled)
    }

    func testStartingWithoutRegistrationAfterForceQuittingStartsListener_butNotTheBroadcaster() {
        appDelegate.persistence = PersistenceDouble()

        let options: [UIApplication.LaunchOptionsKey: Any]? = [.bluetoothPeripherals: []]
        _ = appDelegate.application(UIApplication.shared, didFinishLaunchingWithOptions: options)

        // do not make them from scratch
        XCTAssertFalse(nursery.startListenerCalled)
        XCTAssertFalse(nursery.startBroadcasterCalled)

        // remake only the listener in this case, since we can't broadcast (yet)
        XCTAssertTrue(nursery.startListenerCalled)
        XCTAssertFalse(nursery.startBroadcasterCalled)
    }

}

class MockBluetoothNursery: BluetoothNursery {
    
    var contactEventRepository: ContactEventRepository = DummyContactEventRepository()
    
    var contactEventPersister: ContactEventPersister = DummyContactEventPersister()
    
    var startBroadcasterCalled = false
    var startListenerCalled = false
    var recreateListenerWasCalled = false
    var recreateBroadcasterWasCalled = false
    
    func startBroadcaster(stateDelegate: BTLEBroadcasterStateDelegate?, registration: Registration) {
        self.startBroadcasterCalled = true
    }
    
    func startListener(stateDelegate: BTLEListenerStateDelegate?) {
        self.startListenerCalled = true
    }

    func recreateListener(launchOptions: [UIApplication.LaunchOptionsKey : Any]?) {
        self.recreateListenerWasCalled = true
    }

    func recreateBroadcaster(launchOptions: [UIApplication.LaunchOptionsKey : Any]?) {
        self.recreateBroadcasterWasCalled = true
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
