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

let SonarBTPeripheralManagerOptionShowPowerAlertKey = CBPeripheralManagerOptionShowPowerAlertKey
let SonarBTPeripheralManagerOptionRestoreIdentifierKey = CBPeripheralManagerOptionRestoreIdentifierKey
let SonarBTPeripheralManagerRestoredStateServicesKey = CBPeripheralManagerRestoredStateServicesKey
let SonarBTPeripheralManagerRestoredStateAdvertisementDataKey = CBPeripheralManagerRestoredStateAdvertisementDataKey

typealias SonarBTPeripheralManagerAuthorizationStatus = CBPeripheralManagerAuthorizationStatus
class SonarBTPeripheralManager: NSObject {
    weak var delegate: SonarBTPeripheralManagerDelegate?
    private var cbPeripheralManager: CBPeripheralManager!
    
    init(delegate: SonarBTPeripheralManagerDelegate?, queue: DispatchQueue?, options: [String : Any]? = nil) {
        self.delegate = delegate
        super.init()
        
        self.cbPeripheralManager = CBPeripheralManager(delegate: self, queue: queue, options: options)
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
        delegate?.peripheralManager(self, willRestoreState: wrapState(dict))
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
    
    private func wrapState(_ dict: [String : Any]) -> [String : Any] {
        return dict.reduce([:]) { (partialResult: [String: Any], tuple: (key: String, value: Any)) in
            var result = partialResult
            switch (tuple.value) {
            case let services as [CBMutableService]: result[tuple.key] = services.map { service in SonarBTService(service) }
            case let services as [CBService]: result[tuple.key] = services.map { service in SonarBTService(service) }
            case let characteristics as [CBCharacteristic]: result[tuple.key] = characteristics.map { characteristic in SonarBTCharacteristic(characteristic) }
            default:
                result[tuple.key] = tuple.value
            }
            return result
        }
    }
}
