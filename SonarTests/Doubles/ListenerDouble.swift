//
//  BTLEListenerDouble.swift
//  SonarTests
//
//  Created by NHSX on 4/23/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
@testable import Sonar

class ListenerDouble: Listener {
    var connectedPeripheral: Peripheral?

    func start(stateDelegate: ListenerStateDelegate?, delegate: ListenerDelegate?) {
    }
    
    func connect(_ peripheral: Peripheral) {
        self.connectedPeripheral = peripheral
    }

    func isHealthy() -> Bool {
        return false
    }
}
