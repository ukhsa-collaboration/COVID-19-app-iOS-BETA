//
//  SonarBTPeripheralManager.swift
//  Sonar
//
//  Created by NHSX on 16/6/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CoreBluetooth

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

public let SonarBTPeripheralManagerOptionShowPowerAlertKey = CBPeripheralManagerOptionShowPowerAlertKey
public let SonarBTPeripheralManagerOptionRestoreIdentifierKey = CBPeripheralManagerOptionRestoreIdentifierKey
public let SonarBTPeripheralManagerRestoredStateServicesKey = CBPeripheralManagerRestoredStateServicesKey
public let SonarBTPeripheralManagerRestoredStateAdvertisementDataKey = CBPeripheralManagerRestoredStateAdvertisementDataKey

typealias SonarBTPeripheralManagerAuthorizationStatus = CBPeripheralManagerAuthorizationStatus
class SonarBTPeripheralManager: NSObject {
    weak var delegate: SonarBTPeripheralManagerDelegate?
    private let cbPeripheralManager: CBPeripheralManager
    
    init(delegate: SonarBTPeripheralManagerDelegate?, queue: DispatchQueue?, options: [String : Any]? = nil) {
        self.delegate = delegate
        self.cbPeripheralManager = CBPeripheralManager(delegate: nil, queue: queue, options: options)
        super.init()
        cbPeripheralManager.delegate = self
    }
    
    var isAdvertising: Bool {
        return cbPeripheralManager.isAdvertising
    }
    
    var state: SonarBTManagerState {
        return cbPeripheralManager.state
    }
    
    class func authorizationStatus() -> SonarBTPeripheralManagerAuthorizationStatus {
        return CBPeripheralManager.authorizationStatus()
    }
    
    func add(_ service: SonarBTService) {
        cbPeripheralManager.add(service.unwrapMutable)
    }
    
    func startAdvertising(_ advertisementData: [String : Any]?) {
        cbPeripheralManager.startAdvertising(advertisementData)
    }
    
    func updateValue(_ value: Data, for characteristic: SonarBTCharacteristic, onSubscribedCentrals centrals: [SonarBTCentral]?) -> Bool {
        return cbPeripheralManager.updateValue(value, for: characteristic.unwrapMutable, onSubscribedCentrals: centrals)
    }
    
    func respond(to request: SonarBTATTRequest, withResult result: SonarBTATTError.Code) {
        cbPeripheralManager.respond(to: request.unwrap, withResult: result)
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
        delegate?.peripheralManager(self, central: central, didSubscribeTo: SonarBTCharacteristic(characteristic))
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        delegate?.peripheralManager(self, central: central, didUnsubscribeFrom: SonarBTCharacteristic(characteristic))
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        delegate?.peripheralManager(self, didReceiveRead: SonarBTATTRequest(request))
    }
}
