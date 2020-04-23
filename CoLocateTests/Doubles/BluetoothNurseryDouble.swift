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
    
    var contactEventRepository: ContactEventRepository = ContactEventRepositoryDouble()
    var contactEventPersister: ContactEventPersister = ContactEventPersisterDouble()
    
    func startBroadcaster(stateDelegate: BTLEBroadcasterStateDelegate?) {
    }
    func startListener(stateDelegate: BTLEListenerStateDelegate?) {
    }

    func recreateListener(launchOptions: [UIApplication.LaunchOptionsKey : Any]?) {
    }

    func recreateBroadcaster(launchOptions: [UIApplication.LaunchOptionsKey : Any]?) {
    }
}
