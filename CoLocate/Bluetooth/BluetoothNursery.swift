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
    
    let contactEventRecorder: ContactEventRecorder
    let contactEventCollector: ContactEventCollector
    
    let listenerQueue: DispatchQueue? = DispatchQueue(label: "BTLE Listener Queue")
    let broadcasterQueue: DispatchQueue? = DispatchQueue(label: "BTLE Broadcaster Queue")
    
    var central: CBCentralManager?
    var listener: BTLEListener?
    
    var peripheral: CBPeripheralManager?
    var broadcaster: BTLEBroadcaster?
    
    var startListenerCalled: Bool = false
    var startBroadcasterCalled: Bool = false
    
    init() {
        contactEventRecorder = PlistContactEventRecorder.shared
        contactEventCollector = ContactEventCollector(contactEventRecorder: contactEventRecorder)
    }
    
    func startListener(stateDelegate: BTLEListenerStateDelegate?) {
        startListenerCalled = true
        listener = ConcreteBTLEListener(contactEventRecorder: contactEventRecorder)
        central = CBCentralManager(delegate: listener as! ConcreteBTLEListener, queue: listenerQueue, options: [
            CBCentralManagerOptionRestoreIdentifierKey: BluetoothNursery.centralRestoreIdentifier
        ])
        (listener as? ConcreteBTLEListener)?.stateDelegate = stateDelegate
        (listener as? ConcreteBTLEListener)?.delegate = contactEventCollector
    }
    
    func startBroadcaster(stateDelegate: BTLEBroadcasterStateDelegate?) {
        startBroadcasterCalled = true
        broadcaster = ConcreteBTLEBroadcaster()
        peripheral = CBPeripheralManager(delegate: broadcaster as! ConcreteBTLEBroadcaster, queue: broadcasterQueue, options: [
            CBPeripheralManagerOptionRestoreIdentifierKey: BluetoothNursery.peripheralRestoreIdentifier
        ])
        (broadcaster as? ConcreteBTLEBroadcaster)?.stateDelegate = stateDelegate
    }
    
}
