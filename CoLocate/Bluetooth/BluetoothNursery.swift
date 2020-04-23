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
    var stateObserver: BluetoothStateObserver? { get }
    
    func createListener()
    func createBroadcaster(stateDelegate: BTLEBroadcasterStateDelegate?, registration: Registration)
}

class ConcreteBluetoothNursery: BluetoothNursery {
    
    static let centralRestoreIdentifier: String = "SonarCentralRestoreIdentifier"
    static let peripheralRestoreIdentifier: String = "SonarPeripheralRestoreIdentifier"
    
    let contactEventPersister: ContactEventPersister
    let contactEventRepository: ContactEventRepository
    let broadcastIdGenerator: BroadcastIdGenerator
    // Created when createListener() is called, because creating an observer can propmt the user for BT permissions
    // and we want to control when that happens in the onboarding flow.
    public private(set) var stateObserver: BluetoothStateObserver? = nil
    
    private let listenerQueue: DispatchQueue? = DispatchQueue(label: "BTLE Listener Queue")
    private let broadcasterQueue: DispatchQueue? = DispatchQueue(label: "BTLE Broadcaster Queue")
    private let persistence: Persisting
    private let userNotificationCenter: UserNotificationCenter
    private let contactEventExpiryHandler: ContactEventExpiryHandler
    private var central: CBCentralManager?
    private var listener: BTLEListener?
    private var peripheral: CBPeripheralManager?
    private var broadcaster: BTLEBroadcaster?
    private var userNotifier: BluetoothStateUserNotifier?

    init(persistence: Persisting, userNotificationCenter: UserNotificationCenter, notificationCenter: NotificationCenter) {
        self.persistence = persistence
        self.userNotificationCenter = userNotificationCenter
        contactEventPersister = PlistPersister<UUID, ContactEvent>(fileName: "contactEvents")
        contactEventRepository = PersistingContactEventRepository(persister: contactEventPersister)
        broadcastIdGenerator = ConcreteBroadcastIdGenerator(storage: SecureBroadcastRotationKeyStorage())
        contactEventExpiryHandler = ContactEventExpiryHandler(notificationCenter: notificationCenter, contactEventRepository: contactEventRepository)
    }

    // MARK: - BTLEListener

    func createListener() {
        let listener = ConcreteBTLEListener(persistence: persistence)
        central = CBCentralManager(delegate: listener, queue: listenerQueue, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(true),
            CBCentralManagerOptionRestoreIdentifierKey: ConcreteBluetoothNursery.centralRestoreIdentifier,
            CBCentralManagerOptionShowPowerAlertKey: NSNumber(true),
        ])
        listener.delegate = contactEventRepository
        
        self.stateObserver = BluetoothStateObserver(initialState: central!.state)
        listener.stateDelegate = self.stateObserver
        userNotifier = BluetoothStateUserNotifier(
            appStateReader: UIApplication.shared,
            bluetoothStateObserver: self.stateObserver!,
            scheduler: HumbleLocalNotificationScheduler(userNotificationCenter: userNotificationCenter)
        )
        
        self.listener = listener
    }

    // MARK: - BTLEBroadaster
    
    func createBroadcaster(stateDelegate: BTLEBroadcasterStateDelegate?, registration: Registration) {
        broadcastIdGenerator.sonarId = registration.id

        let concreteBroadcaster = ConcreteBTLEBroadcaster(idGenerator: broadcastIdGenerator)
        peripheral = CBPeripheralManager(delegate: concreteBroadcaster,
                                         queue: broadcasterQueue,
                                         options: [CBPeripheralManagerOptionRestoreIdentifierKey: ConcreteBluetoothNursery.peripheralRestoreIdentifier])
        concreteBroadcaster.peripheral = peripheral
        concreteBroadcaster.start()

        broadcaster = concreteBroadcaster
    }

}

// MARK: - Logging
private let logger = Logger(label: "BTLE")
