//
//  BluetoothNursery.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CoreBluetooth

class BluetoothNursery {
    
    static let centralRestoreIdentifier: String = "SonarCentralRestoreIdentifier"
    static let peripheralRestoreIdentifier: String = "SonarPeripheralRestoreIdentifier"
    
    let listenerQueue: DispatchQueue? = DispatchQueue(label: "BTLE Listener Queue")
    let broadcasterQueue: DispatchQueue? = DispatchQueue(label: "BTLE Broadcaster Queue")
    
    let persistence: Persistence
    let contactEventPersister: PlistPersister<ContactEvent>
    let contactEventRepository: PersistingContactEventRepository
    
    var central: CBCentralManager?
    var listener: BTLEListener?
    
    var peripheral: CBPeripheralManager?
    var broadcaster: BTLEBroadcaster?
    
    var startListenerCalled: Bool = false
    var startBroadcasterCalled: Bool = false
    
    init(persistence: Persistence) {
        self.persistence = persistence
        contactEventPersister = PlistPersister<ContactEvent>(fileName: "contactEvents")
        contactEventRepository = PersistingContactEventRepository(persister: contactEventPersister)
    }

    func startBroadcastingAndListening(registration: Registration) {
        ConcreteBroadcastIdGenerator.shared.sonarId = registration.id

        startBroadcaster(stateDelegate: nil)
        startListener(stateDelegate: BluetoothStateObserver.shared)
    }
    
    func startListener(stateDelegate: BTLEListenerStateDelegate?) {
        startListenerCalled = true
        listener = ConcreteBTLEListener(persistence: persistence)
        central = CBCentralManager(delegate: listener as! ConcreteBTLEListener, queue: listenerQueue, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(true),
            CBCentralManagerOptionRestoreIdentifierKey: BluetoothNursery.centralRestoreIdentifier
        ])
        (listener as? ConcreteBTLEListener)?.stateDelegate = stateDelegate
        (listener as? ConcreteBTLEListener)?.delegate = contactEventRepository
    }
    
    func startBroadcaster(stateDelegate: BTLEBroadcasterStateDelegate?) {
        startBroadcasterCalled = true
        broadcaster = ConcreteBTLEBroadcaster()
        peripheral = CBPeripheralManager(delegate: broadcaster as! ConcreteBTLEBroadcaster, queue: broadcasterQueue, options: [
            CBPeripheralManagerOptionRestoreIdentifierKey: BluetoothNursery.peripheralRestoreIdentifier
        ])
        (broadcaster as? ConcreteBTLEBroadcaster)?.stateDelegate = stateDelegate

        // TODO (tj) : I think this is unnecessary when the permissions view controller calls us
        broadcaster?.tryStartAdvertising()
    }
    
}
