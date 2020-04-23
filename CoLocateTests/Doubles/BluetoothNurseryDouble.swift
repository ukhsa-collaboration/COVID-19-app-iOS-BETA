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
    
    func createListener(stateDelegate: BTLEListenerStateDelegate?) {
    }
    
    func createBroadcaster(stateDelegate: BTLEBroadcasterStateDelegate?, registration: Registration) {
    }
    
    func restoreListener(_ restorationIdentifiers: [String]) {
    }
    
    func restoreBroadcaster(_ restorationIdentifiers: [String]) {
    }

}
