//
//  BluetoothNurseryDouble.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
@testable import CoLocate

class BluetoothNurseryDouble: BluetoothNursery {
    var stateObserver: BluetoothStateObserver?
    var contactEventRepository: ContactEventRepository = ContactEventRepositoryDouble()
    var contactEventPersister: ContactEventPersister = ContactEventPersisterDouble()
    var createListenerCalled = false
    var createBroadcasterCalled = false
    
    func createListener() {
        createListenerCalled = true
        stateObserver = BluetoothStateObserver(initialState: .unknown)
    }
    
    func createBroadcaster(stateDelegate: BTLEBroadcasterStateDelegate?, registration: Registration) {
        createBroadcasterCalled = true
    }
    
}
