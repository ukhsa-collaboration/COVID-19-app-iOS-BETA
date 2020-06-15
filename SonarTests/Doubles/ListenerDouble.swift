//
//  BTLEListenerDouble.swift
//  SonarTests
//
//  Created by NHSX on 4/23/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import CoreBluetooth
@testable import Sonar

class ListenerDouble: BTLEListener {
    var connectedPeripheral: Peripheral?

    override func start(stateDelegate: ListenerStateDelegate?, delegate: ListenerDelegate?) {
    }
    
    func connect(_ peripheral: Peripheral) {
        self.connectedPeripheral = peripheral
    }

    override func isHealthy() -> Bool {
        return false
    }
}
