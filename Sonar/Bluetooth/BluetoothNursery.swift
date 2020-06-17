//
//  BluetoothNursery.swift
//  Sonar
//
//  Created by NHSX on 03.04.20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

import Logging

protocol BluetoothNursery {
    var contactEventRepository: ContactEventRepository { get }
    var contactEventPersister: ContactEventPersister { get }
    var stateObserver: BluetoothStateObserving { get }
    var broadcaster: BTLEBroadcaster? { get }
    var listener: BTLEListener? { get }

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
    public var broadcastPayloadService: BroadcastPayloadService?

    public var listener: BTLEListener?
    public private(set) var stateObserver: BluetoothStateObserving = BluetoothStateObserver(initialState: .unknown)

    private var central: SonarBTCentralManager?
    private var peripheral: SonarBTPeripheralManager?
    
    private var broadcastPayloadRotationTimer: BroadcastPayloadRotationTimer?
    
    private let peripheralManagerFactory: (() -> SonarBTPeripheralManager)?
    private let centralManagerFactory: ((_ listener: BTLEListener) -> SonarBTCentralManager)?
    
    init(
        persistence: Persisting,
        userNotificationCenter: UserNotificationCenter,
        notificationCenter: NotificationCenter,
        monitor: AppMonitoring,
        peripheralManagerFactory: (() -> SonarBTPeripheralManager)? = nil,
        centralManagerFactory: ((_ listener: BTLEListener) -> SonarBTCentralManager)? = nil
    ) {
        self.persistence = persistence
        self.userNotificationCenter = userNotificationCenter
        self.peripheralManagerFactory = peripheralManagerFactory
        self.centralManagerFactory = centralManagerFactory
        
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
        logger.info("Starting the bluetooth nursery with sonar id \(registration == nil ? "not set" : "set")")

        broadcastPayloadService = SonarBroadcastPayloadService(
            storage: SecureBroadcastRotationKeyStorage(),
            persistence: persistence,
            encrypter: ConcreteBroadcastIdEncrypter())
        
        let broadcaster = BTLEBroadcaster(broadcastPayloadService: broadcastPayloadService!)
        if let peripheralManagerFactory = peripheralManagerFactory {
            peripheral = peripheralManagerFactory()
        } else {
            peripheral = SonarBTPeripheralManager(delegate: broadcaster, queue: btleQueue, options: [
                SonarBTPeripheralManagerOptionRestoreIdentifierKey: ConcreteBluetoothNursery.peripheralRestoreIdentifier
            ])
        }
        self.broadcaster = broadcaster
        
        listener = BTLEListener(broadcaster: broadcaster, queue: btleQueue)
        
        if let centralManagerFactory = centralManagerFactory {
            central = centralManagerFactory(listener!)
        } else {
            central = SonarBTCentralManager(
                delegate: listener,
                peripheralDelegate: listener,
                queue: btleQueue, options: [
                    SonarBTCentralManagerScanOptionAllowDuplicatesKey: NSNumber(true),
                    SonarBTCentralManagerOptionRestoreIdentifierKey: ConcreteBluetoothNursery.centralRestoreIdentifier,
                    SonarBTCentralManagerOptionShowPowerAlertKey: NSNumber(true),
            ])
        }
        listener?.delegate = contactEventRepository
        listener?.stateDelegate = self.stateObserver
        userNotifier = BluetoothStateUserNotifier(
            appStateReader: UIApplication.shared,
            bluetoothStateObserver: self.stateObserver,
            scheduler: HumbleLocalNotificationScheduler(userNotificationCenter: userNotificationCenter)
        )
                
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
