//
//  TestBTLEListener.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
@testable import CoLocate

class TestBTLEListener: BTLEListener {

    var connectedPeripheral: BTLEPeripheral?
    
    func start(stateDelegate: BTLEListenerStateDelegate?, delegate: BTLEListenerDelegate?) {
    }

    func connect(_ peripheral: BTLEPeripheral) {
        self.connectedPeripheral = peripheral
    }

}
