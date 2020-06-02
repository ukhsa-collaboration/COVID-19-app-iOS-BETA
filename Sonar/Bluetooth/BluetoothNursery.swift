//
//  BluetoothNursery.swift
//  Sonar
//
//  Created by NHSX on 03.04.20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import CoreBluetooth

import Logging

protocol BluetoothNursery {
    var contactEventRepository: ContactEventRepository { get }
    var contactEventPersister: ContactEventPersister { get }
    var stateObserver: BluetoothStateObserving { get }
    var broadcaster: BTLEBroadcaster? { get }

    func startBluetooth(registration: Registration?)
    var hasStarted: Bool { get }
}

class ConcreteBluetoothNursery: BluetoothNursery, PersistenceDelegate {
    
    static let centralRestoreIdentifier: String = "SonarCentralRestoreIdentifier"
    static let peripheralRestoreIdentifier: String = "SonarPeripheralRestoreIdentifier"
    
    let contactEventPersister: ContactEventPersister
    let contactEventRepository: ContactEventRepository
    private var userNotifier: BluetoothStateUserNotifier?
    private let btleQueue: DispatchQueue = DispatchQueue(label: "BTLE Queue")
    private let persistence: Persisting
    private let userNotificationCenter: UserNotificationCenter
    private let contactEventExpiryHandler: ContactEventExpiryHandler
    private let dailyMetricsCollector: DailyMetricsCollector

    // The listener needs to get hold of the broadcaster, to send keepalives
    public var broadcaster: BTLEBroadcaster?
    public var broadcastIdGenerator: BroadcastPayloadGenerator?

    public var listener: BTLEListener?
    public private(set) var stateObserver: BluetoothStateObserving = BluetoothStateObserver(initialState: .unknown)

    private var central: CBCentralManager?
    private var peripheral: CBPeripheralManager?
    
    private var broadcastPayloadRotationTimer: BroadcastPayloadRotationTimer?
    
    init(
        persistence: Persisting,
        userNotificationCenter: UserNotificationCenter,
        notificationCenter: NotificationCenter,
        monitor: AppMonitoring
    ) {
        self.persistence = persistence
        self.userNotificationCenter = userNotificationCenter
        contactEventPersister = PlistPersister<UUID, ContactEvent>(fileName: "contactEvents")
        contactEventRepository = PersistingContactEventRepository(persister: contactEventPersister)
        

        contactEventExpiryHandler = ContactEventExpiryHandler(notificationCenter: notificationCenter,
                                                              contactEventRepository: contactEventRepository)
        dailyMetricsCollector = DailyMetricsCollector(
            notificationCenter: notificationCenter,
            contactEventRepository: contactEventRepository,
            defaults: UserDefaults.standard,
            monitor: monitor
        )

        self.persistence.delegate = self
    }

    // MARK: - BTLEListener

    func startBluetooth(registration: Registration?) {
        logger.info("Starting the bluetooth nursery with sonar id \(registration == nil ? "not set" : "set"))")

        broadcastIdGenerator = SonarBroadcastPayloadGenerator(
            storage: SecureBroadcastRotationKeyStorage(),
            persistence: persistence,
            encrypter: ConcreteBroadcastIdEncrypter())
        
        let broadcaster = ConcreteBTLEBroadcaster(idGenerator: broadcastIdGenerator!)
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
        listener.stateDelegate = self.stateObserver
        userNotifier = BluetoothStateUserNotifier(
            appStateReader: UIApplication.shared,
            bluetoothStateObserver: self.stateObserver,
            scheduler: HumbleLocalNotificationScheduler(userNotificationCenter: userNotificationCenter)
        )
        
        self.listener = listener
        
        broadcastPayloadRotationTimer = BroadcastPayloadRotationTimer(broadcaster: broadcaster, queue: btleQueue)
        broadcastPayloadRotationTimer?.scheduleNextMidnightUTC()
    }
    
    var hasStarted: Bool { return self.listener != nil }
    
    // MARK: - PersistenceDelegate

    func persistence(_ persistence: Persisting, didUpdateRegistration registration: Registration) {
        logger.info("saved registration, updating broadcastId")

        broadcaster?.updateIdentity()
    }

    // MARK: - Health

    public var isHealthy: Bool {
        guard listener != nil else { return false }
        guard broadcaster != nil else { return false }
        guard userNotifier != nil else { return false }
        guard peripheral != nil else { return false }
        guard central != nil else { return false }
        guard userNotifier != nil else { return false }

        guard broadcaster!.isHealthy() else { return false }
        guard listener!.isHealthy() else { return false }

        return true
    }
}

// MARK: - Logging
private let logger = Logger(label: "BTLE")
