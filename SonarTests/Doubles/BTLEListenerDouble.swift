//
//  BTLEListenerDouble.swift
//  SonarTests
//
//  Created by NHSX on 4/23/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
@testable import Sonar

class BTLEListenerDouble: BTLEListener {
    var connectedPeripheral: BTLEPeripheral?

    func start(stateDelegate: BTLEListenerStateDelegate?, delegate: BTLEListenerDelegate?) {
    }
    
    func connect(_ peripheral: BTLEPeripheral) {
        self.connectedPeripheral = peripheral
    }

    func isHealthy() -> Bool {
        return false
    }
}
