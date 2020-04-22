//
//  BluetoothStateObserverDouble.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import CoreBluetooth
@testable import CoLocate

class BluetoothStateObserverDouble: BluetoothStateObserver {
    var currentState: CBManagerState
    var delegate: BluetoothStateObserverDelegate?
    
    init(initialState: CBManagerState = .unknown) {
        currentState = initialState
    }
    
    func state() -> CBManagerState {
        return currentState
    }
}
