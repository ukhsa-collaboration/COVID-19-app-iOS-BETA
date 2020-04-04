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
    
    var central: CBCentralManager?
    var listener: BTLEListener?
    
    var peripheral: CBPeripheralManager?
    var broadcaster: BTLEBroadcaster?
    
    init() {
        contactEventRecorder = PlistContactEventRecorder.shared
        contactEventCollector = ContactEventCollector(contactEventRecorder: contactEventRecorder)
    }
    
    func startListener(stateDelegate: BTLEListenerStateDelegate?) {
        listener = ConcreteBTLEListener(contactEventRecorder: contactEventRecorder)
        central = CBCentralManager(delegate: listener as! ConcreteBTLEListener, queue: nil, options: [
            CBCentralManagerOptionRestoreIdentifierKey: BluetoothNursery.centralRestoreIdentifier
        ])
        (listener as? ConcreteBTLEListener)?.stateDelegate = stateDelegate
        (listener as? ConcreteBTLEListener)?.delegate = contactEventCollector
    }
    
    func startBroadcaster(stateDelegate: BTLEBroadcasterStateDelegate?, sonarId: UUID) {
        broadcaster = ConcreteBTLEBroadcaster(sonarId: sonarId)
        peripheral = CBPeripheralManager(delegate: broadcaster as! ConcreteBTLEBroadcaster, queue: nil, options: [
            CBPeripheralManagerOptionRestoreIdentifierKey: BluetoothNursery.peripheralRestoreIdentifier
        ])
        (broadcaster as? ConcreteBTLEBroadcaster)?.stateDelegate = stateDelegate
    }
    
}
