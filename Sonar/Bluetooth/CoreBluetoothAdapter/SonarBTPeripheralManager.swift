//
//  SonarBTPeripheralManager.swift
//  Sonar
//
//  Created by NHSX on 16/6/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CoreBluetooth

class SonarBTCentral {
    private let cbCentral: CBCentral
    
    init(_ central: CBCentral) {
        self.cbCentral = central
    }
}

class SonarBTATTRequest {
    private let cbATTRequest: CBATTRequest
    
    init(_ request: CBATTRequest) {
        self.cbATTRequest = request
    }
}

protocol SonarBTPeripheralManagerDelegate: class {
    func peripheralManagerDidUpdateState(_ peripheral: SonarBTPeripheralManager)
    func peripheralManager(_ peripheral: SonarBTPeripheralManager, willRestoreState dict: [String : Any])
    func peripheralManager(_ peripheral: SonarBTPeripheralManager, didAdd service: SonarBTService, error: Error?)
    func peripheralManagerDidStartAdvertising(_ peripheral: SonarBTPeripheralManager, error: Error?)
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: SonarBTPeripheralManager)
    func peripheralManager(_ peripheral: SonarBTPeripheralManager, central: SonarBTCentral, didSubscribeTo characteristic: SonarBTCharacteristic)
    func peripheralManager(_ peripheral: SonarBTPeripheralManager, central: SonarBTCentral, didUnsubscribeFrom characteristic: SonarBTCharacteristic)
    func peripheralManager(_ peripheral: SonarBTPeripheralManager, didReceiveRead request: SonarBTATTRequest)
}

class SonarBTPeripheralManager: NSObject {
    weak var delegate: SonarBTPeripheralManagerDelegate?
    private let cbPeripheralManager: CBPeripheralManager
    
    init(delegate: SonarBTPeripheralManagerDelegate?, queue: DispatchQueue?, options: [String : Any]? = nil) {
        self.delegate = delegate
        self.cbPeripheralManager = CBPeripheralManager(delegate: nil, queue: queue, options: options)
        super.init()
        cbPeripheralManager.delegate = self
    }
}

extension SonarBTPeripheralManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        delegate?.peripheralManagerDidUpdateState(self)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
        delegate?.peripheralManager(self, willRestoreState: dict)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        delegate?.peripheralManager(self, didAdd: SonarBTService(service), error: error)
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        delegate?.peripheralManagerDidStartAdvertising(self, error: error)
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        delegate?.peripheralManagerIsReady(toUpdateSubscribers: self)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        delegate?.peripheralManager(self, central: SonarBTCentral(central), didSubscribeTo: SonarBTCharacteristic(characteristic))
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        delegate?.peripheralManager(self, central: SonarBTCentral(central), didUnsubscribeFrom: SonarBTCharacteristic(characteristic))
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        delegate?.peripheralManager(self, didReceiveRead: SonarBTATTRequest(request))
    }
}
