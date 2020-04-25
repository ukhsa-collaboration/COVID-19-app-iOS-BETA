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
    var broadcaster: BTLEBroadcaster? { get }

    func startBluetooth(registration: Registration?)
}

@objc class ConcreteBluetoothNursery: NSObject, BluetoothNursery, PersistenceDelegate {
    
    static let centralRestoreIdentifier: String = "SonarCentralRestoreIdentifier"
    static let peripheralRestoreIdentifier: String = "SonarPeripheralRestoreIdentifier"
    
    let contactEventPersister: ContactEventPersister
    let contactEventRepository: ContactEventRepository
    private var userNotifier: BluetoothStateUserNotifier?
    private let btleQueue: DispatchQueue = DispatchQueue(label: "BTLE Queue")
    private let persistence: Persisting
    private let userNotificationCenter: UserNotificationCenter
    private let contactEventExpiryHandler: ContactEventExpiryHandler

    // The listener needs to get hold of the broadcaster, to send keepalives
    var broadcaster: BTLEBroadcaster?
    let broadcastIdGenerator: BroadcastIdGenerator

    private var listener: BTLEListener?
    // This observer is created along with the listener, because creating an observer
    // can prompt the user for BT permissions and we want to control when that happens in the onboarding flow.
    public private(set) var stateObserver: BluetoothStateObserver? = nil

    private var central: CBCentralManager?
    private var peripheral: CBPeripheralManager?

    init(persistence: Persisting, userNotificationCenter: UserNotificationCenter, notificationCenter: NotificationCenter) {
        self.persistence = persistence
        self.userNotificationCenter = userNotificationCenter
        contactEventPersister = PlistPersister<UUID, ContactEvent>(fileName: "contactEvents")
        contactEventRepository = PersistingContactEventRepository(persister: contactEventPersister)
        broadcastIdGenerator = ConcreteBroadcastIdGenerator(storage: SecureBroadcastRotationKeyStorage())

        contactEventExpiryHandler = ContactEventExpiryHandler(notificationCenter: notificationCenter,
                                                              contactEventRepository: contactEventRepository)

        super.init()
        self.persistence.delegate = self
    }

    // MARK: - BTLEListener

    func startBluetooth(registration: Registration?) {
        broadcastIdGenerator.sonarId = registration?.id
        
        let broadcaster = ConcreteBTLEBroadcaster(idGenerator: broadcastIdGenerator)
        peripheral = CBPeripheralManager(delegate: broadcaster, queue: btleQueue, options: [
            CBPeripheralManagerOptionRestoreIdentifierKey: ConcreteBluetoothNursery.peripheralRestoreIdentifier
        ])
        self.broadcaster = broadcaster
        
        let listener = ConcreteBTLEListener(broadcaster: broadcaster, queue: btleQueue)
        central = CBCentralManager(delegate: listener, queue: btleQueue, options: [
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
    
    // MARK: - PersistenceDelegate

    func persistence(_ persistence: Persisting, didUpdateRegistration registration: Registration) {
        broadcastIdGenerator.sonarId = registration.id
        broadcaster?.updateIdentity()
    }

    // MARK: - Health

    @objc dynamic public var isHealthy: Bool {
        guard listener != nil else { return false }
        guard broadcaster != nil else { return false }
        guard userNotifier != nil else { return false }
        guard peripheral != nil else { return false }
        guard central != nil else { return false }
        guard stateObserver != nil else { return false }
        guard userNotifier != nil else { return false }

        guard broadcaster!.isHealthy() else { return false }
        guard listener!.isHealthy() else { return false }

        return true
    }
}

// MARK: - Logging
private let logger = Logger(label: "BTLE")
