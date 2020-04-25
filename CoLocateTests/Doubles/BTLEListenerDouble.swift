//
//  BTLEListenerDouble.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
@testable import CoLocate

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
