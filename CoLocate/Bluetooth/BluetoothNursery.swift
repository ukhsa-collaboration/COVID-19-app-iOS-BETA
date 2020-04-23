//
//  BluetoothNursery.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import CoreBluetooth

import Logging

protocol BluetoothNursery {
    var contactEventRepository: ContactEventRepository { get }
    var contactEventPersister: ContactEventPersister { get }
    
    func createListener(stateDelegate: BTLEListenerStateDelegate?)
    func createBroadcaster(stateDelegate: BTLEBroadcasterStateDelegate?, registration: Registration)

    func restoreListener(_ restorationIdentifiers: [String])
    func restoreBroadcaster(_ restorationIdentifiers: [String])
}


class ConcreteBluetoothNursery: BluetoothNursery {
    static let centralRestoreIdentifier: String = "SonarCentralRestoreIdentifier"
    static let peripheralRestoreIdentifier: String = "SonarPeripheralRestoreIdentifier"
    
    let listenerQueue: DispatchQueue? = DispatchQueue(label: "BTLE Listener Queue")
    let broadcasterQueue: DispatchQueue? = DispatchQueue(label: "BTLE Broadcaster Queue")
    
    let persistence: Persisting
    let contactEventPersister: ContactEventPersister
    let contactEventRepository: ContactEventRepository
    let broadcastIdGenerator: BroadcastIdGenerator
    let stateObserver: BluetoothStateUserNotifier
    let contactEventExpiryHandler: ContactEventExpiryHandler
    
    var central: CBCentralManager?
    var listener: BTLEListener?
    
    var peripheral: CBPeripheralManager?
    var broadcaster: BTLEBroadcaster?
    
    var startListenerCalled: Bool = false
    var startBroadcasterCalled: Bool = false
    
    init(persistence: Persisting, userNotificationCenter: UNUserNotificationCenter, notificationCenter: NotificationCenter) {
        self.persistence = persistence
        contactEventPersister = PlistPersister<UUID, ContactEvent>(fileName: "contactEvents")
        contactEventRepository = PersistingContactEventRepository(persister: contactEventPersister)
        broadcastIdGenerator = ConcreteBroadcastIdGenerator(storage: SecureBroadcastRotationKeyStorage())
        stateObserver = BluetoothStateUserNotifier(
            appStateReader: UIApplication.shared,
            scheduler: HumbleLocalNotificationScheduler(userNotificationCenter: userNotificationCenter)
        )
        contactEventExpiryHandler = ContactEventExpiryHandler(notificationCenter: notificationCenter, contactEventRepository: contactEventRepository)
    }

    // MARK: - BTLEListener

    func createListener(stateDelegate: BTLEListenerStateDelegate?) {
        startListenerCalled = true
        listener = ConcreteBTLEListener(persistence: persistence)
        central = CBCentralManager(delegate: listener as! ConcreteBTLEListener, queue: listenerQueue, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(true),
            CBCentralManagerOptionRestoreIdentifierKey: ConcreteBluetoothNursery.centralRestoreIdentifier,
            CBCentralManagerOptionShowPowerAlertKey: NSNumber(true),
        ])
        (listener as? ConcreteBTLEListener)?.stateDelegate = stateDelegate
        (listener as? ConcreteBTLEListener)?.delegate = contactEventRepository
    }

    func restoreListener(_ restorationIdentifiers: [String]) {
        #warning("needs an implementation here")
    }

    // MARK: - BTLEBroadaster
    
    func createBroadcaster(stateDelegate: BTLEBroadcasterStateDelegate?, registration: Registration) {
        logger.info("starting BLE broadcaster and listener with sonar id (\(registration.id))")

        broadcastIdGenerator.sonarId = registration.id

        startBroadcasterCalled = true
        broadcaster = ConcreteBTLEBroadcaster(idGenerator: broadcastIdGenerator)
        peripheral = CBPeripheralManager(delegate: broadcaster as! ConcreteBTLEBroadcaster, queue: broadcasterQueue, options: [
            CBPeripheralManagerOptionRestoreIdentifierKey: ConcreteBluetoothNursery.peripheralRestoreIdentifier
        ])
        (broadcaster as? ConcreteBTLEBroadcaster)?.stateDelegate = stateDelegate

        broadcaster?.start()
    }

    // TODO: should this take in the registration as well ?
    // otherwise the id generator won't have it and we never get a chance to broadcast :(
    func restoreBroadcaster(_ restorationIdentifiers: [String]) {
        #warning("needs an implementation here")
    }
}

// MARK: - Logging
private let logger = Logger(label: "BTLE")
